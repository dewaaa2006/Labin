import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { NotificationType } from '@prisma/client';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';

const router = Router();
router.use(requireAuth);

router.get('/', asyncHandler(async (req, res) => {
  const query = z.object({ type: z.nativeEnum(NotificationType).optional(), isRead: z.coerce.boolean().optional() }).parse(req.query);
  ok(res, await prisma.notification.findMany({
    where: { userId: req.user!.id, ...(query.type ? { type: query.type } : {}), ...(query.isRead === undefined ? {} : { isRead: query.isRead }) },
    orderBy: { createdAt: 'desc' },
  }));
}));

router.get('/unread-count', asyncHandler(async (req, res) => {
  ok(res, { count: await prisma.notification.count({ where: { userId: req.user!.id, isRead: false } }) });
}));

router.put('/read-all', asyncHandler(async (req, res) => {
  await prisma.notification.updateMany({ where: { userId: req.user!.id, isRead: false }, data: { isRead: true } });
  ok(res, { read: true });
}));

router.put('/:id/read', asyncHandler(async (req, res) => {
  await prisma.notification.updateMany({ where: { id: String(req.params.id), userId: req.user!.id }, data: { isRead: true } });
  ok(res, { read: true });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await prisma.notification.deleteMany({ where: { id: String(req.params.id), userId: req.user!.id } });
  ok(res, { deleted: true });
}));

export default router;
