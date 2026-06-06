import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { Role } from '@prisma/client';
import { z } from 'zod';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { upload, fileUrl } from '../middleware/upload.js';
import { ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';

const router = Router();
const schema = z.object({
  name: z.string().min(2),
  code: z.string().min(2),
  capacity: z.coerce.number().int().positive(),
  floor: z.string().optional(),
  building: z.string().optional(),
  facilities: z.preprocess((v) => typeof v === 'string' ? v.split(',').map((x) => x.trim()).filter(Boolean) : v, z.array(z.string()).default([])),
  description: z.string().optional(),
});

function parseFacilities(room: { facilities: string }) {
  try {
    return { ...room, facilities: JSON.parse(room.facilities) as string[] };
  } catch {
    return { ...room, facilities: [] };
  }
}

function serializeRoomBody(body: z.infer<typeof schema>) {
  return { ...body, facilities: JSON.stringify(body.facilities) };
}

router.get('/', asyncHandler(async (req, res) => {
  const query = z.object({ search: z.string().optional(), capacity: z.coerce.number().optional() }).parse(req.query);
  const rooms = await prisma.room.findMany({
    where: {
      isActive: true,
      ...(query.search ? { name: { contains: query.search } } : {}),
      ...(query.capacity ? { capacity: { gte: query.capacity } } : {}),
    },
    orderBy: { name: 'asc' },
  });
  ok(res, rooms.map(parseFacilities));
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const room = await prisma.room.findUniqueOrThrow({
    where: { id: String(req.params.id) },
    include: { bookings: { where: { date: today, status: { in: ['APPROVED', 'ONGOING'] } }, orderBy: { startTime: 'asc' } } },
  });
  ok(res, { ...parseFacilities(room), bookings: room.bookings });
}));

router.post('/', requireAuth, requireRole(Role.ADMIN), upload.single('image'), asyncHandler(async (req, res) => {
  const room = await prisma.room.create({ data: { ...serializeRoomBody(schema.parse(req.body)), imageUrl: fileUrl(req.file) } });
  ok(res, parseFacilities(room));
}));

router.put('/:id', requireAuth, requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  const body = schema.partial().parse(req.body);
  const { facilities, ...rest } = body;
  const data = { ...rest, ...(facilities ? { facilities: JSON.stringify(facilities) } : {}) };
  const room = await prisma.room.update({ where: { id: String(req.params.id) }, data });
  ok(res, parseFacilities(room));
}));

router.delete('/:id', requireAuth, requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  ok(res, await prisma.room.update({ where: { id: String(req.params.id) }, data: { isActive: false } }));
}));

export default router;
