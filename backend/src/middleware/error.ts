import type { ErrorRequestHandler } from 'express';
import { Prisma } from '@prisma/client';
import { ZodError } from 'zod';
import { AppError } from '../utils/api.js';

const databaseUrlPlaceholders = ['PROJECT_REF', 'YOUR_DB_PASSWORD', 'REGION'];

function hasPlaceholderDatabaseUrl() {
  const databaseUrl = process.env.DATABASE_URL ?? '';
  return databaseUrlPlaceholders.some((placeholder) => databaseUrl.includes(placeholder));
}

export const notFound = () => {
  throw new AppError(404, 'Endpoint tidak ditemukan.');
};

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof ZodError) {
    return res.status(422).json({
      success: false,
      message: 'Validasi gagal.',
      errors: error.flatten().fieldErrors,
    });
  }

  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      success: false,
      message: error.message,
      ...(error.errors ? { errors: error.errors } : {}),
    });
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      return res.status(409).json({ success: false, message: 'Data sudah digunakan.' });
    }
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Data tidak ditemukan.' });
    }
  }

  if (hasPlaceholderDatabaseUrl()) {
    return res.status(503).json({
      success: false,
      message: 'DATABASE_URL Supabase belum valid. Ganti PROJECT_REF, YOUR_DB_PASSWORD, dan REGION dengan connection string asli dari tombol Connect di Supabase.',
    });
  }

  console.error(error);
  return res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
};
