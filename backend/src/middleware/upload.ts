import fs from 'node:fs';
import path from 'node:path';
import multer from 'multer';
import { env } from '../utils/env.js';

fs.mkdirSync(env.uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, env.uploadDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname);
    const base = path.basename(file.originalname, ext).replace(/[^a-z0-9-_]/gi, '-').toLowerCase();
    cb(null, `${Date.now()}-${base}${ext}`);
  },
});

export const upload = multer({
  storage,
  limits: { fileSize: env.maxFileSize },
});

export function fileUrl(file?: Express.Multer.File) {
  return file ? `/uploads/${file.filename}` : undefined;
}
