import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { ReportStatus, Role, Urgency } from '@prisma/client';
import { z } from 'zod';
import { isOperator, requireAuth, requireRole } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { AppError, ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';
import { generateTracking } from '../utils/tokens.js';
import { pagination } from '../validators/common.js';
import { notifyUser } from '../services/notification.service.js';

const router = Router();
router.use(requireAuth);

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = pagination(req.query);
  const query = z.object({ status: z.nativeEnum(ReportStatus).optional(), urgency: z.nativeEnum(Urgency).optional() }).parse(req.query);
  const where = {
    ...(isOperator(req.user!.role) ? {} : { userId: req.user!.id }),
    ...(query.status ? { status: query.status } : {}),
    ...(query.urgency ? { urgency: query.urgency } : {}),
  };
  const [items, total] = await Promise.all([
    prisma.damageReport.findMany({ where, include: { user: true }, skip, take: limit, orderBy: { createdAt: 'desc' } }),
    prisma.damageReport.count({ where }),
  ]);
  ok(res, items, { page, limit, total });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const item = await prisma.damageReport.findUniqueOrThrow({ where: { id: String(req.params.id) }, include: { user: true } });
  if (!isOperator(req.user!.role) && item.userId !== req.user!.id) throw new AppError(403, 'Kamu tidak punya akses untuk ini.');
  ok(res, item);
}));

router.post('/', upload.array('photos', 5), asyncHandler(async (req, res) => {
  const body = z.object({
    location: z.string().min(2),
    facilityName: z.string().min(2),
    description: z.string().min(30),
    urgency: z.nativeEnum(Urgency),
  }).parse(req.body);
  const files = (req.files as Express.Multer.File[] | undefined) ?? [];
  ok(res, await prisma.damageReport.create({
    data: { ...body, userId: req.user!.id, trackingId: generateTracking('RPT'), photos: files.map((file) => `/uploads/${file.filename}`) },
  }));
}));

router.put('/:id/status', requireRole(Role.ADMIN, Role.STAFF), asyncHandler(async (req, res) => {
  const body = z.object({ status: z.nativeEnum(ReportStatus), technicianNote: z.string().optional() }).parse(req.body);
  const item = await prisma.damageReport.update({ where: { id: String(req.params.id) }, data: { ...body, resolvedAt: body.status === 'RESOLVED' ? new Date() : undefined } });
  await notifyUser({ userId: item.userId, type: 'REPORT_UPDATE', title: 'Laporan Diperbarui', message: `Laporan ${item.trackingId} diperbarui: ${item.status}`, relatedId: item.id, relatedType: 'report' });
  ok(res, item);
}));

export default router;
