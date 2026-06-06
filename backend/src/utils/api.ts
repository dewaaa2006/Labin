import type { Response } from 'express';

export function ok(res: Response, data: unknown = null, meta?: unknown) {
  return res.json({ success: true, data, ...(meta ? { meta } : {}) });
}

export class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public errors?: unknown,
  ) {
    super(message);
  }
}
