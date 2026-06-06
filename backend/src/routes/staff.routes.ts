import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { ApplicationStatus, AttendanceMethod, Role, ShiftType } from '@prisma/client';
import { z } from 'zod';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { AppError, ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';
import { notifyUser } from '../services/notification.service.js';

const router = Router();
router.use(requireAuth);

const shiftSchema = z.object({
  userId: z.string().uuid(),
  roomId: z.string().uuid(),
  date: z.coerce.date(),
  startTime: z.string(),
  endTime: z.string(),
  shiftType: z.nativeEnum(ShiftType).default('REGULAR'),
  notes: z.string().optional(),
});

router.get('/shifts', requireRole(Role.STAFF, Role.ADMIN), asyncHandler(async (req, res) => {
  const query = z.object({ userId: z.string().optional(), date: z.coerce.date().optional(), week: z.string().optional() }).parse(req.query);
  ok(res, await prisma.staffShift.findMany({
    where: { ...(query.userId ? { userId: query.userId } : {}), ...(query.date ? { date: query.date } : {}) },
    include: { user: true, room: true, attendance: true },
    orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
  }));
}));

router.post('/shifts', requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  ok(res, await prisma.staffShift.create({ data: shiftSchema.parse(req.body) }));
}));

router.put('/shifts/:id', requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  ok(res, await prisma.staffShift.update({ where: { id: String(req.params.id) }, data: shiftSchema.partial().parse(req.body) }));
}));

router.delete('/shifts/:id', requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  ok(res, await prisma.staffShift.delete({ where: { id: String(req.params.id) } }));
}));

router.post('/shifts/:id/checkin', requireRole(Role.STAFF), asyncHandler(async (req, res) => {
  const body = z.object({ method: z.nativeEnum(AttendanceMethod).default('MANUAL'), latitude: z.coerce.number().optional(), longitude: z.coerce.number().optional(), notes: z.string().optional() }).parse(req.body);
  const shift = await prisma.staffShift.findUniqueOrThrow({ where: { id: String(req.params.id) } });
  if (shift.userId !== req.user!.id) throw new AppError(403, 'Shift ini bukan milikmu.');
  ok(res, await prisma.attendance.upsert({
    where: { shiftId: shift.id },
    create: { shiftId: shift.id, userId: req.user!.id, checkIn: new Date(), ...body },
    update: { checkIn: new Date(), ...body },
  }));
}));

router.post('/shifts/:id/checkout', requireRole(Role.STAFF), asyncHandler(async (req, res) => {
  const shift = await prisma.staffShift.findUniqueOrThrow({ where: { id: String(req.params.id) } });
  if (shift.userId !== req.user!.id) throw new AppError(403, 'Shift ini bukan milikmu.');
  ok(res, await prisma.attendance.update({ where: { shiftId: shift.id }, data: { checkOut: new Date() } }));
}));

router.get('/attendance', requireRole(Role.STAFF, Role.ADMIN), asyncHandler(async (req, res) => {
  const query = z.object({ userId: z.string().optional(), month: z.coerce.number().optional(), year: z.coerce.number().optional() }).parse(req.query);
  ok(res, await prisma.attendance.findMany({
    where: { ...(req.user!.role === 'STAFF' ? { userId: req.user!.id } : query.userId ? { userId: query.userId } : {}) },
    include: { shift: { include: { room: true } }, user: true },
    orderBy: { createdAt: 'desc' },
  }));
}));

router.get('/applications', requireRole(Role.ADMIN), asyncHandler(async (_req, res) => {
  ok(res, await prisma.staffApplication.findMany({ orderBy: { createdAt: 'desc' } }));
}));

router.post('/applications', requireRole(Role.STUDENT), upload.single('document'), asyncHandler(async (req, res) => {
  const body = z.object({ motivation: z.string().min(20), experience: z.string().optional(), availability: z.string().min(3) }).parse(req.body);
  ok(res, await prisma.staffApplication.create({
    data: { ...body, userId: req.user!.id, documentUrl: req.file ? `/uploads/${req.file.filename}` : undefined },
  }));
}));

router.put('/applications/:id', requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  const body = z.object({ status: z.nativeEnum(ApplicationStatus), reviewNote: z.string().optional() }).parse(req.body);
  const app = await prisma.staffApplication.update({ where: { id: String(req.params.id) }, data: { ...body, reviewedBy: req.user!.id, reviewedAt: new Date() } });
  if (body.status === 'ACCEPTED') await prisma.user.update({ where: { id: app.userId }, data: { role: 'STAFF' } });
  await notifyUser({ userId: app.userId, type: 'SYSTEM', title: 'Lamaran Student Staff Direview', message: 'Lamaran student staff kamu telah direview.', relatedId: app.id, relatedType: 'staffApplication' });
  ok(res, app);
}));

router.get('/my-shifts', requireRole(Role.STAFF), asyncHandler(async (req, res) => {
  ok(res, await prisma.staffShift.findMany({
    where: { userId: req.user!.id, date: { gte: new Date() } },
    include: { room: true, attendance: true },
    orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
  }));
}));

export default router;
