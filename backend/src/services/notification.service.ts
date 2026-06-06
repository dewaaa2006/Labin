import { NotificationType } from '@prisma/client';
import { prisma } from '../utils/prisma.js';

export async function notifyUser(input: {
  userId: string;
  title: string;
  message: string;
  type: NotificationType;
  relatedId?: string;
  relatedType?: string;
}) {
  return prisma.notification.create({ data: input });
}

export async function broadcastAnnouncement(announcementId: string, title: string) {
  const users = await prisma.user.findMany({ where: { isActive: true }, select: { id: true } });
  if (!users.length) return;
  await prisma.notification.createMany({
    data: users.map((user) => ({
      userId: user.id,
      title: 'Pengumuman Baru',
      message: title,
      type: 'ANNOUNCEMENT',
      relatedId: announcementId,
      relatedType: 'announcement',
    })),
  });
}
