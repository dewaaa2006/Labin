import type { NextFunction, Request, Response } from 'express';
import type { Role, User } from '@prisma/client';
import { AppError } from '../utils/api.js';
import { prisma } from '../utils/prisma.js';
import { verifyAccessToken } from '../utils/tokens.js';

export type AuthUser = Pick<User, 'id' | 'email' | 'role' | 'name' | 'isActive'>;

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export async function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw new AppError(401, 'Token tidak ditemukan.');

  const payload = verifyAccessToken(token);
  const user = await prisma.user.findUnique({
    where: { id: payload.id },
    select: { id: true, email: true, role: true, name: true, isActive: true },
  });
  if (!user || !user.isActive) throw new AppError(401, 'Akun tidak aktif atau tidak ditemukan.');
  req.user = user;
  next();
}

export function requireRole(...roles: Role[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) throw new AppError(401, 'Login diperlukan.');
    if (!roles.includes(req.user.role)) throw new AppError(403, 'Kamu tidak punya akses untuk ini.');
    next();
  };
}

export function isOperator(role: Role) {
  return role === 'ADMIN' || role === 'STAFF';
}
