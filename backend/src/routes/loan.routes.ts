import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { LoanStatus, Role } from '@prisma/client';
import { z } from 'zod';
import { isOperator, requireAuth, requireRole } from '../middleware/auth.js';
import { upload, fileUrl } from '../middleware/upload.js';
import { AppError, ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';
import { generateTracking } from '../utils/tokens.js';
import { pagination } from '../validators/common.js';
import { notifyUser } from '../services/notification.service.js';

const router = Router();
router.use(requireAuth);

const createSchema = z.object({
  equipmentId: z.string().uuid(),
  quantity: z.coerce.number().int().positive(),
  borrowDate: z.coerce.date(),
  returnDate: z.coerce.date(),
  purpose: z.string().min(20),
});

router.get('/my/active', asyncHandler(async (req, res) => {
  ok(res, await prisma.loan.findMany({
    where: { userId: req.user!.id, status: { in: ['PENDING', 'APPROVED', 'TAKEN', 'OVERDUE'] } },
    include: { equipment: true },
    orderBy: { createdAt: 'desc' },
  }));
}));

router.get('/stats/summary', requireRole(Role.ADMIN), asyncHandler(async (_req, res) => {
  const byStatus = await prisma.loan.groupBy({ by: ['status'], _count: true });
  ok(res, { total: await prisma.loan.count(), byStatus, overdue: await prisma.loan.count({ where: { status: 'OVERDUE' } }) });
}));

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = pagination(req.query);
  const query = z.object({
    status: z.nativeEnum(LoanStatus).optional(),
    userId: z.string().optional(),
    equipmentId: z.string().optional(),
    dateFrom: z.coerce.date().optional(),
    dateTo: z.coerce.date().optional(),
  }).parse(req.query);
  const where = {
    ...(isOperator(req.user!.role) ? (query.userId ? { userId: query.userId } : {}) : { userId: req.user!.id }),
    ...(query.status ? { status: query.status } : {}),
    ...(query.equipmentId ? { equipmentId: query.equipmentId } : {}),
    ...(query.dateFrom || query.dateTo ? { borrowDate: { ...(query.dateFrom ? { gte: query.dateFrom } : {}), ...(query.dateTo ? { lte: query.dateTo } : {}) } } : {}),
  };
  const [items, total] = await Promise.all([
    prisma.loan.findMany({ where, include: { user: true, equipment: true }, skip, take: limit, orderBy: { createdAt: 'desc' } }),
    prisma.loan.count({ where }),
  ]);
  ok(res, items, { page, limit, total });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const loan = await prisma.loan.findUniqueOrThrow({ where: { id: String(req.params.id) }, include: { user: true, equipment: true } });
  if (!isOperator(req.user!.role) && loan.userId !== req.user!.id) throw new AppError(403, 'Kamu tidak punya akses untuk ini.');
  ok(res, loan);
}));

router.post('/', requireRole(Role.STUDENT, Role.LECTURER), upload.single('document'), asyncHandler(async (req, res) => {
  const body = createSchema.parse(req.body);
  if (body.returnDate <= body.borrowDate) throw new AppError(422, 'Tanggal kembali harus setelah tanggal pinjam.');
  const equipment = await prisma.equipment.findUniqueOrThrow({ where: { id: body.equipmentId } });
  if (equipment.availableStock < body.quantity) throw new AppError(422, 'Stok alat tidak mencukupi.');
  const loan = await prisma.loan.create({
    data: { ...body, userId: req.user!.id, trackingId: generateTracking('LBN'), documentUrl: fileUrl(req.file) },
    include: { equipment: true },
  });
  ok(res, loan);
}));

router.put('/:id/approve', requireRole(Role.ADMIN, Role.STAFF), asyncHandler(async (req, res) => {
  const loan = await prisma.loan.findUniqueOrThrow({ where: { id: String(req.params.id) }, include: { equipment: true } }) as any;
  if (loan.equipment.availableStock < loan.quantity) throw new AppError(422, 'Stok alat tidak mencukupi.');
  const updated = await prisma.$transaction(async (tx) => {
    await tx.equipment.update({ where: { id: loan.equipmentId }, data: { availableStock: { decrement: loan.quantity } } });
    return tx.loan.update({ where: { id: loan.id }, data: { status: 'APPROVED', approvedBy: req.user!.id, approvedAt: new Date() }, include: { equipment: true } });
  });
  await notifyUser({ userId: loan.userId, type: 'LOAN_APPROVED', title: 'Peminjaman Disetujui', message: `Peminjaman ${updated.equipment.name} disetujui.`, relatedId: loan.id, relatedType: 'loan' });
  ok(res, updated);
}));

router.put('/:id/reject', requireRole(Role.ADMIN, Role.STAFF), asyncHandler(async (req, res) => {
  const { adminNote } = z.object({ adminNote: z.string().min(3) }).parse(req.body);
  const loan = await prisma.loan.update({ where: { id: String(req.params.id) }, data: { status: 'REJECTED', adminNote }, include: { equipment: true } }) as any;
  await notifyUser({ userId: loan.userId, type: 'LOAN_REJECTED', title: 'Peminjaman Ditolak', message: `Peminjaman ${loan.equipment.name} ditolak. Alasan: ${adminNote}`, relatedId: loan.id, relatedType: 'loan' });
  ok(res, loan);
}));

router.put('/:id/take', requireRole(Role.ADMIN, Role.STAFF), asyncHandler(async (req, res) => {
  ok(res, await prisma.loan.update({ where: { id: String(req.params.id) }, data: { status: 'TAKEN' } }));
}));

router.put('/:id/return', requireRole(Role.ADMIN, Role.STAFF), asyncHandler(async (req, res) => {
  const loan = await prisma.loan.findUniqueOrThrow({ where: { id: String(req.params.id) } });
  const updated = await prisma.$transaction(async (tx) => {
    await tx.equipment.update({ where: { id: loan.equipmentId }, data: { availableStock: { increment: loan.quantity } } });
    return tx.loan.update({ where: { id: loan.id }, data: { status: 'RETURNED', actualReturn: new Date() } });
  });
  ok(res, updated);
}));

router.put('/:id/cancel', asyncHandler(async (req, res) => {
  const loan = await prisma.loan.findUniqueOrThrow({ where: { id: String(req.params.id) } });
  if (loan.userId !== req.user!.id && !isOperator(req.user!.role)) throw new AppError(403, 'Kamu tidak punya akses untuk ini.');
  if (loan.status !== 'PENDING') throw new AppError(422, 'Hanya peminjaman pending yang bisa dibatalkan.');
  ok(res, await prisma.loan.update({ where: { id: loan.id }, data: { status: 'CANCELLED' } }));
}));

export default router;
