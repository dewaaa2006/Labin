import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: Number(process.env.PORT ?? 3001),
  frontendUrl: process.env.FRONTEND_URL ?? 'http://localhost:5173',
  accessSecret: process.env.JWT_ACCESS_SECRET ?? 'dev-access-secret',
  refreshSecret: process.env.JWT_REFRESH_SECRET ?? 'dev-refresh-secret',
  accessExpiry: process.env.JWT_ACCESS_EXPIRY ?? '15m',
  refreshDays: Number(process.env.JWT_REFRESH_EXPIRY_DAYS ?? 30),
  uploadDir: process.env.UPLOAD_DIR ?? './uploads',
  maxFileSize: Number(process.env.MAX_FILE_SIZE ?? 5242880),
  fromEmail: process.env.FROM_EMAIL ?? 'noreply@labin.id',
  smtp: {
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT ?? 587),
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
};
