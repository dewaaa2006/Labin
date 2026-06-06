import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { EquipmentCategory, EquipmentCondition, Role } from '@prisma/client';
import { z } from 'zod';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { upload, fileUrl } from '../middleware/upload.js';
import { ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';
import { pagination } from '../validators/common.js';

const router = Router();

const bodySchema = z.object({
  name: z.string().min(2),
  category: z.nativeEnum(EquipmentCategory),
  description: z.string().min(5),
  specifications: z.string().optional(),
  totalStock: z.coerce.number().int().min(0).default(1),
  availableStock: z.coerce.number().int().min(0).optional(),
  condition: z.nativeEnum(EquipmentCondition).default('GOOD'),
});

router.get('/categories/summary', asyncHandler(async (_req, res) => {
  const categories = await prisma.equipment.groupBy({
    by: ['category'],
    where: { isActive: true },
    _count: true,
    _sum: { totalStock: true, availableStock: true },
  });
  ok(res, categories);
}));

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = pagination(req.query);
  const query = z.object({
    category: z.nativeEnum(EquipmentCategory).optional(),
    condition: z.nativeEnum(EquipmentCondition).optional(),
    available: z.coerce.boolean().optional(),
    search: z.string().optional(),
  }).parse(req.query);
  const where = {
    isActive: true,
    ...(query.category ? { category: query.category } : {}),
    ...(query.condition ? { condition: query.condition } : {}),
    ...(query.available ? { availableStock: { gt: 0 } } : {}),
    ...(query.search ? { name: { contains: query.search, mode: 'insensitive' as const } } : {}),
  };
  const [items, total] = await Promise.all([
    prisma.equipment.findMany({ where, skip, take: limit, orderBy: { name: 'asc' } }),
    prisma.equipment.count({ where }),
  ]);
  ok(res, items, { page, limit, total });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const item = await prisma.equipment.findUniqueOrThrow({ where: { id: String(req.params.id) } });
  const activeLoans = await prisma.loan.count({ where: { equipmentId: item.id, status: { in: ['PENDING', 'APPROVED', 'TAKEN'] } } });
  const history = await prisma.loan.findMany({
    where: { equipmentId: item.id },
    take: 5,
    orderBy: { createdAt: 'desc' },
    select: { id: true, borrowDate: true, returnDate: true, status: true },
  });
  ok(res, { ...item, activeLoans, history });
}));

router.post('/', requireAuth, requireRole(Role.ADMIN), upload.single('image'), asyncHandler(async (req, res) => {
  const body = bodySchema.parse(req.body);
  const data = { ...body, availableStock: body.availableStock ?? body.totalStock, imageUrl: fileUrl(req.file) };
  ok(res, await prisma.equipment.create({ data }));
}));

router.put('/:id', requireAuth, requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  const body = bodySchema.partial().parse(req.body);
  ok(res, await prisma.equipment.update({ where: { id: String(req.params.id) }, data: body }));
}));

router.delete('/:id', requireAuth, requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  ok(res, await prisma.equipment.update({ where: { id: String(req.params.id) }, data: { isActive: false } }));
}));

router.post('/:id/image', requireAuth, requireRole(Role.ADMIN), upload.single('image'), asyncHandler(async (req, res) => {
  const imageUrl = fileUrl(req.file);
  ok(res, await prisma.equipment.update({ where: { id: String(req.params.id) }, data: { imageUrl } }));
}));

export default router;
