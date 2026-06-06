import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { ActivityType, BookingStatus, Role } from '@prisma/client';
import { z } from 'zod';
import { isOperator, requireAuth, requireRole } from '../middleware/auth.js';
import { AppError, ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';
import { generateTracking } from '../utils/tokens.js';
import { pagination } from '../validators/common.js';
import { notifyUser } from '../services/notification.service.js';

const router = Router();

const schema = z.object({
  roomId: z.string().uuid(),
  date: z.coerce.date(),
  startTime: z.string().regex(/^\d{2}:\d{2}$/),
  endTime: z.string().regex(/^\d{2}:\d{2}$/),
  activityName: z.string().min(3),
  activityType: z.nativeEnum(ActivityType),
  participants: z.coerce.number().int().positive(),
  notes: z.string().optional(),
});

router.get('/room/:roomId/slots', asyncHandler(async (req, res) => {
  const date = z.coerce.date().parse(req.query.date);
  const slots = await prisma.booking.findMany({
    where: { roomId: String(req.params.roomId), date, status: { in: ['APPROVED', 'ONGOING', 'PENDING'] } },
    select: { id: true, startTime: true, endTime: true, activityName: true, status: true },
    orderBy: { startTime: 'asc' },
  });
  ok(res, slots);
}));

router.use(requireAuth);

router.get('/my/upcoming', asyncHandler(async (req, res) => {
  ok(res, await prisma.booking.findMany({
    where: { userId: req.user!.id, date: { gte: new Date() }, status: { in: ['PENDING', 'APPROVED', 'ONGOING'] } },
    include: { room: true },
    orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
  }));
}));

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = pagination(req.query);
  const query = z.object({
    status: z.nativeEnum(BookingStatus).optional(),
    roomId: z.string().optional(),
    date: z.coerce.date().optional(),
  }).parse(req.query);
  const where = {
    ...(isOperator(req.user!.role) ? {} : { userId: req.user!.id }),
    ...(query.status ? { status: query.status } : {}),
    ...(query.roomId ? { roomId: query.roomId } : {}),
    ...(query.date ? { date: query.date } : {}),
  };
  const [items, total] = await Promise.all([
    prisma.booking.findMany({ where, include: { user: true, room: true }, skip, take: limit, orderBy: { createdAt: 'desc' } }),
    prisma.booking.count({ where }),
  ]);
  ok(res, items, { page, limit, total });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const item = await prisma.booking.findUniqueOrThrow({ where: { id: String(req.params.id) }, include: { user: true, room: true } });
  if (!isOperator(req.user!.role) && item.userId !== req.user!.id) throw new AppError(403, 'Kamu tidak punya akses untuk ini.');
  ok(res, item);
}));

router.post('/', asyncHandler(async (req, res) => {
  const body = schema.parse(req.body);
  if (body.endTime <= body.startTime) throw new AppError(422, 'Jam selesai harus setelah jam mulai.');
  const room = await prisma.room.findUniqueOrThrow({ where: { id: body.roomId } });
  if (body.participants > room.capacity) throw new AppError(422, 'Jumlah peserta melebihi kapasitas ruangan.');
  const conflict = await prisma.booking.findFirst({
    where: {
      roomId: body.roomId,
      date: body.date,
      status: { in: ['PENDING', 'APPROVED', 'ONGOING'] },
      startTime: { lt: body.endTime },
      endTime: { gt: body.startTime },
    },
  });
  if (conflict) throw new AppError(409, 'Slot waktu sudah terpakai.');
  ok(res, await prisma.booking.create({ data: { ...body, userId: req.user!.id, trackingId: generateTracking('BKN') }, include: { room: true } }));
}));

router.put('/:id/approve', requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  const item = await prisma.booking.update({ where: { id: String(req.params.id) }, data: { status: 'APPROVED', approvedBy: req.user!.id, approvedAt: new Date() }, include: { room: true } }) as any;
  await notifyUser({ userId: item.userId, type: 'BOOKING_APPROVED', title: 'Reservasi Disetujui', message: `Reservasi ${item.room.name} tanggal ${item.date.toISOString().slice(0, 10)} disetujui.`, relatedId: item.id, relatedType: 'booking' });
  ok(res, item);
}));

router.put('/:id/reject', requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  const { adminNote } = z.object({ adminNote: z.string().min(3) }).parse(req.body);
  const item = await prisma.booking.update({ where: { id: String(req.params.id) }, data: { status: 'REJECTED', adminNote }, include: { room: true } }) as any;
  await notifyUser({ userId: item.userId, type: 'BOOKING_REJECTED', title: 'Reservasi Ditolak', message: `Reservasi ${item.room.name} ditolak. Alasan: ${adminNote}`, relatedId: item.id, relatedType: 'booking' });
  ok(res, item);
}));

router.put('/:id/cancel', asyncHandler(async (req, res) => {
  const item = await prisma.booking.findUniqueOrThrow({ where: { id: String(req.params.id) } });
  if (item.userId !== req.user!.id && req.user!.role !== 'ADMIN') throw new AppError(403, 'Kamu tidak punya akses untuk ini.');
  if (item.status !== 'PENDING') throw new AppError(422, 'Hanya reservasi pending yang bisa dibatalkan.');
  ok(res, await prisma.booking.update({ where: { id: item.id }, data: { status: 'CANCELLED' } }));
}));

export default router;
