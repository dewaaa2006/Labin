import crypto from 'node:crypto';
import asyncHandler from 'express-async-handler';
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import nodemailer from 'nodemailer';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { upload, fileUrl } from '../middleware/upload.js';
import { AppError, ok } from '../utils/api.js';
import { env } from '../utils/env.js';
import { prisma } from '../utils/prisma.js';
import { createRefreshToken, signAccessToken } from '../utils/tokens.js';

const router = Router();

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(8),
  nim: z.string().optional(),
  university: z.string().optional(),
  faculty: z.string().optional(),
  studyProgram: z.string().optional(),
  phone: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

function setRefreshCookie(res: import('express').Response, token: string, expiresAt: Date) {
  res.cookie('refreshToken', token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    expires: expiresAt,
  });
}

async function issueAuth(res: import('express').Response, user: { id: string; role: any; email: string }) {
  const accessToken = signAccessToken(user);
  const refresh = await createRefreshToken(user.id);
  setRefreshCookie(res, refresh.token, refresh.expiresAt);
  return accessToken;
}

router.post('/register', asyncHandler(async (req, res) => {
  const body = registerSchema.parse(req.body);
  const password = await bcrypt.hash(body.password, 12);
  const user = await prisma.user.create({
    data: { ...body, password },
    select: { id: true, name: true, email: true, role: true, nim: true, university: true, faculty: true, studyProgram: true, phone: true, avatarUrl: true },
  });
  const accessToken = await issueAuth(res, user);
  ok(res, { user, accessToken });
}));

router.post('/login', asyncHandler(async (req, res) => {
  const body = loginSchema.parse(req.body);
  const user = await prisma.user.findUnique({ where: { email: body.email } });
  if (!user || !user.isActive) throw new AppError(401, 'Email atau password salah.');
  const valid = await bcrypt.compare(body.password, user.password);
  if (!valid) throw new AppError(401, 'Email atau password salah.');
  const accessToken = await issueAuth(res, user);
  const { password, resetToken, resetExpiresAt, ...safeUser } = user;
  ok(res, { user: safeUser, accessToken });
}));

router.post('/refresh', asyncHandler(async (req, res) => {
  const token = req.cookies.refreshToken;
  if (!token) throw new AppError(401, 'Refresh token tidak ditemukan.');
  const stored = await prisma.refreshToken.findUnique({ where: { token }, include: { user: true } });
  if (!stored || stored.expiresAt < new Date() || !stored.user.isActive) throw new AppError(401, 'Refresh token tidak valid.');
  const accessToken = signAccessToken(stored.user);
  ok(res, { accessToken });
}));

router.post('/logout', asyncHandler(async (req, res) => {
  const token = req.cookies.refreshToken;
  if (token) await prisma.refreshToken.deleteMany({ where: { token } });
  res.clearCookie('refreshToken');
  ok(res, { loggedOut: true });
}));

router.get('/me', requireAuth, asyncHandler(async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
    select: { id: true, name: true, email: true, nim: true, role: true, university: true, faculty: true, studyProgram: true, phone: true, avatarUrl: true, createdAt: true },
  });
  ok(res, user);
}));

router.put('/me', requireAuth, asyncHandler(async (req, res) => {
  const body = z.object({
    name: z.string().min(2).optional(),
    phone: z.string().optional().nullable(),
    university: z.string().optional().nullable(),
    faculty: z.string().optional().nullable(),
    studyProgram: z.string().optional().nullable(),
  }).parse(req.body);
  const user = await prisma.user.update({ where: { id: req.user!.id }, data: body });
  const { password, resetToken, resetExpiresAt, ...safeUser } = user;
  ok(res, safeUser);
}));

router.put('/me/password', requireAuth, asyncHandler(async (req, res) => {
  const body = z.object({ oldPassword: z.string(), newPassword: z.string().min(8) }).parse(req.body);
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  const valid = await bcrypt.compare(body.oldPassword, user.password);
  if (!valid) throw new AppError(400, 'Password lama salah.');
  await prisma.user.update({ where: { id: user.id }, data: { password: await bcrypt.hash(body.newPassword, 12) } });
  ok(res, { changed: true });
}));

router.post('/me/avatar', requireAuth, upload.single('avatar'), asyncHandler(async (req, res) => {
  const avatarUrl = fileUrl(req.file);
  if (!avatarUrl) throw new AppError(422, 'File avatar wajib diupload.');
  await prisma.user.update({ where: { id: req.user!.id }, data: { avatarUrl } });
  ok(res, { avatarUrl });
}));

router.post('/forgot-password', asyncHandler(async (req, res) => {
  const { email } = z.object({ email: z.string().email() }).parse(req.body);
  const user = await prisma.user.findUnique({ where: { email } });
  if (user) {
    const resetToken = crypto.randomBytes(24).toString('hex');
    await prisma.user.update({
      where: { id: user.id },
      data: { resetToken, resetExpiresAt: new Date(Date.now() + 15 * 60 * 1000) },
    });
    const transporter = nodemailer.createTransport({
      host: env.smtp.host,
      port: env.smtp.port,
      auth: env.smtp.user ? { user: env.smtp.user, pass: env.smtp.pass } : undefined,
    });
    const info = await transporter.sendMail({
      from: env.fromEmail,
      to: email,
      subject: 'Reset Password Labin',
      text: `Reset token kamu: ${resetToken}`,
    });
    const preview = nodemailer.getTestMessageUrl(info);
    if (preview) console.log(`Reset email preview: ${preview}`);
  }
  ok(res, { message: 'Cek email kamu. Link reset valid 15 menit.' });
}));

router.post('/reset-password', asyncHandler(async (req, res) => {
  const body = z.object({ token: z.string(), password: z.string().min(8) }).parse(req.body);
  const user = await prisma.user.findFirst({ where: { resetToken: body.token, resetExpiresAt: { gt: new Date() } } });
  if (!user) throw new AppError(400, 'Token reset tidak valid atau kedaluwarsa.');
  await prisma.user.update({
    where: { id: user.id },
    data: { password: await bcrypt.hash(body.password, 12), resetToken: null, resetExpiresAt: null },
  });
  ok(res, { reset: true });
}));

export default router;
