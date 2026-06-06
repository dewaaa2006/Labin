import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import { AnnouncementCategory, Role } from '@prisma/client';
import { z } from 'zod';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { ok } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';
import { pagination } from '../validators/common.js';
import { broadcastAnnouncement } from '../services/notification.service.js';

const router = Router();
const schema = z.object({
  title: z.string().min(3),
  content: z.string().min(10),
  category: z.nativeEnum(AnnouncementCategory),
  isPinned: z.coerce.boolean().default(false),
  isPublished: z.coerce.boolean().default(true),
});

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = pagination(req.query);
  const query = z.object({ category: z.nativeEnum(AnnouncementCategory).optional(), search: z.string().optional() }).parse(req.query);
  const where = {
    isPublished: true,
    ...(query.category ? { category: query.category } : {}),
    ...(query.search ? { title: { contains: query.search, mode: 'insensitive' as const } } : {}),
  };
  const [items, total] = await Promise.all([
    prisma.announcement.findMany({ where, skip, take: limit, orderBy: [{ isPinned: 'desc' }, { publishedAt: 'desc' }, { createdAt: 'desc' }] }),
    prisma.announcement.count({ where }),
  ]);
  ok(res, items, { page, limit, total });
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const item = await prisma.announcement.update({ where: { id: String(req.params.id) }, data: { viewCount: { increment: 1 } } });
  ok(res, item);
}));

router.post('/', requireAuth, requireRole(Role.ADMIN), upload.array('attachments', 3), asyncHandler(async (req, res) => {
  const body = schema.parse(req.body);
  const files = (req.files as Express.Multer.File[] | undefined) ?? [];
  const item = await prisma.announcement.create({
    data: { ...body, authorId: req.user!.id, attachments: JSON.stringify(files.map((file) => `/uploads/${file.filename}`)), publishedAt: body.isPublished ? new Date() : null },
  });
  if (item.isPublished) await broadcastAnnouncement(item.id, item.title);
  ok(res, item);
}));

router.put('/:id', requireAuth, requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  ok(res, await prisma.announcement.update({ where: { id: String(req.params.id) }, data: schema.partial().parse(req.body) }));
}));

router.delete('/:id', requireAuth, requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  ok(res, await prisma.announcement.delete({ where: { id: String(req.params.id) } }));
}));

router.put('/:id/pin', requireAuth, requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  const item = await prisma.announcement.findUniqueOrThrow({ where: { id: String(req.params.id) } });
  ok(res, await prisma.announcement.update({ where: { id: item.id }, data: { isPinned: !item.isPinned } }));
}));

router.put('/:id/publish', requireAuth, requireRole(Role.ADMIN), asyncHandler(async (req, res) => {
  const item = await prisma.announcement.findUniqueOrThrow({ where: { id: String(req.params.id) } });
  const updated = await prisma.announcement.update({ where: { id: item.id }, data: { isPublished: !item.isPublished, publishedAt: !item.isPublished ? new Date() : item.publishedAt } });
  if (updated.isPublished && !item.isPublished) await broadcastAnnouncement(updated.id, updated.title);
  ok(res, updated);
}));

export default router;
