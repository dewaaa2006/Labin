import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { Role } from '@prisma/client';
import { z } from 'zod';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';
import { pagination } from '../validators/common.js';

const router = Router();
router.use(requireAuth, requireRole(Role.ADMIN));

router.get('/dashboard', asyncHandler(async (_req, res) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const [
    todayLoans,
    pendingLoans,
    pendingBookings,
    totalEquipment,
    availableEquipment,
    totalRooms,
    activeUsers,
    todayBookings,
    unresolvedReports,
    loansByStatus,
    recentLoans,
    recentBookings,
    recentReports,
  ] = await Promise.all([
    prisma.loan.count({ where: { createdAt: { gte: today, lt: tomorrow } } }),
    prisma.loan.count({ where: { status: 'PENDING' } }),
    prisma.booking.count({ where: { status: 'PENDING' } }),
    prisma.equipment.count({ where: { isActive: true } }),
    prisma.equipment.aggregate({ where: { isActive: true }, _sum: { availableStock: true, totalStock: true } }),
    prisma.room.count({ where: { isActive: true } }),
    prisma.user.count({ where: { isActive: true } }),
    prisma.booking.count({ where: { date: today } }),
    prisma.damageReport.count({ where: { status: { in: ['RECEIVED', 'IN_PROGRESS'] } } }),
    prisma.loan.groupBy({ by: ['status'], _count: true }),
    prisma.loan.findMany({ take: 4, orderBy: { createdAt: 'desc' }, include: { user: true, equipment: true } }),
    prisma.booking.findMany({ take: 3, orderBy: { createdAt: 'desc' }, include: { user: true, room: true } }),
    prisma.damageReport.findMany({ take: 3, orderBy: { createdAt: 'desc' }, include: { user: true } }),
  ]);
  ok(res, {
    todayLoans,
    pendingLoans,
    pendingBookings,
    totalEquipment,
    availableEquipment: availableEquipment._sum.availableStock ?? 0,
    totalEquipmentStock: availableEquipment._sum.totalStock ?? 0,
    totalRooms,
    activeUsers,
    todayBookings,
    unresolvedReports,
    loansByStatus: Object.fromEntries(loansByStatus.map((x) => [x.status, x._count])),
    recentActivity: [...recentLoans, ...recentBookings, ...recentReports].slice(0, 10),
  });
}));

router.get('/users', asyncHandler(async (req, res) => {
  const { page, limit, skip } = pagination(req.query);
  const query = z.object({ role: z.nativeEnum(Role).optional(), search: z.string().optional(), isActive: z.coerce.boolean().optional() }).parse(req.query);
  const where = {
    ...(query.role ? { role: query.role } : {}),
    ...(query.isActive === undefined ? {} : { isActive: query.isActive }),
    ...(query.search ? { OR: [{ name: { contains: query.search, mode: 'insensitive' as const } }, { email: { contains: query.search, mode: 'insensitive' as const } }] } : {}),
  };
  const [items, total] = await Promise.all([
    prisma.user.findMany({ where, skip, take: limit, orderBy: { createdAt: 'desc' }, select: { id: true, name: true, email: true, nim: true, role: true, university: true, faculty: true, studyProgram: true, isActive: true, createdAt: true, avatarUrl: true } }),
    prisma.user.count({ where }),
  ]);
  ok(res, items, { page, limit, total });
}));

router.get('/users/:id', asyncHandler(async (req, res) => {
  ok(res, await prisma.user.findUniqueOrThrow({ where: { id: String(req.params.id) }, include: { loans: { include: { equipment: true } }, bookings: { include: { room: true } }, reports: true } }));
}));

router.put('/users/:id/role', asyncHandler(async (req, res) => {
  const { role } = z.object({ role: z.nativeEnum(Role) }).parse(req.body);
  ok(res, await prisma.user.update({ where: { id: String(req.params.id) }, data: { role } }));
}));

router.put('/users/:id/status', asyncHandler(async (req, res) => {
  const { isActive } = z.object({ isActive: z.boolean() }).parse(req.body);
  ok(res, await prisma.user.update({ where: { id: String(req.params.id) }, data: { isActive } }));
}));

router.get('/analytics', asyncHandler(async (_req, res) => {
  const topEquipment = await prisma.loan.groupBy({ by: ['equipmentId'], _count: true, orderBy: { _count: { equipmentId: 'desc' } }, take: 5 });
  const equipmentByCategory = await prisma.equipment.groupBy({ by: ['category'], _count: true });
  const roomOccupancy = await prisma.booking.groupBy({ by: ['roomId'], _count: true, orderBy: { _count: { roomId: 'desc' } }, take: 10 });
  ok(res, { loansOverTime: [], bookingsOverTime: [], topEquipment, equipmentByCategory, roomOccupancy });
}));

function csv(rows: Record<string, unknown>[]) {
  if (!rows.length) return '';
  const headers = Object.keys(rows[0]);
  return [headers.join(','), ...rows.map((row) => headers.map((h) => JSON.stringify(row[h] ?? '')).join(','))].join('\n');
}

router.get('/export/loans', asyncHandler(async (_req, res) => {
  const rows = await prisma.loan.findMany({ include: { user: true, equipment: true } });
  res.header('Content-Type', 'text/csv');
  res.attachment('loans.csv');
  res.send(csv(rows.map((x) => ({ trackingId: x.trackingId, user: x.user.name, equipment: x.equipment.name, status: x.status, borrowDate: x.borrowDate, returnDate: x.returnDate }))));
}));

router.get('/export/bookings', asyncHandler(async (_req, res) => {
  const rows = await prisma.booking.findMany({ include: { user: true, room: true } });
  res.header('Content-Type', 'text/csv');
  res.attachment('bookings.csv');
  res.send(csv(rows.map((x) => ({ trackingId: x.trackingId, user: x.user.name, room: x.room.name, status: x.status, date: x.date, startTime: x.startTime, endTime: x.endTime }))));
}));

router.get('/export/attendance', asyncHandler(async (_req, res) => {
  const rows = await prisma.attendance.findMany({ include: { user: true, shift: { include: { room: true } } } });
  res.header('Content-Type', 'text/csv');
  res.attachment('attendance.csv');
  res.send(csv(rows.map((x) => ({ user: x.user.name, room: x.shift.room.name, date: x.shift.date, checkIn: x.checkIn, checkOut: x.checkOut, method: x.method }))));
}));

export default router;
