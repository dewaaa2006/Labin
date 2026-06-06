import crypto from 'node:crypto';
import jwt, { type SignOptions } from 'jsonwebtoken';
import type { Role, User } from '@prisma/client';
import { env } from './env.js';
import { prisma } from './prisma.js';

export type JwtPayload = { id: string; role: Role; email: string };

export function signAccessToken(user: Pick<User, 'id' | 'role' | 'email'>) {
  const options: SignOptions = { expiresIn: env.accessExpiry as SignOptions['expiresIn'] };
  return jwt.sign({ id: user.id, role: user.role, email: user.email }, env.accessSecret, options);
}

export async function createRefreshToken(userId: string) {
  const token = crypto.randomBytes(48).toString('hex');
  const expiresAt = new Date(Date.now() + env.refreshDays * 24 * 60 * 60 * 1000);
  await prisma.refreshToken.create({ data: { token, userId, expiresAt } });
  return { token, expiresAt };
}

export function verifyAccessToken(token: string) {
  return jwt.verify(token, env.accessSecret) as JwtPayload;
}

export function generateTracking(prefix: string) {
  const date = new Date().toISOString().slice(0, 10).replaceAll('-', '');
  const suffix = Math.random().toString(36).slice(2, 7).toUpperCase();
  return `${prefix}-${date}-${suffix}`;
}
