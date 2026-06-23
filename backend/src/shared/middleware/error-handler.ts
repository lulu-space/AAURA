import type { NextFunction, Request, Response } from 'express';
import { ApiError } from '../../core/errors/api-error.js';

export const errorHandler = (
  error: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  if (error instanceof ApiError) {
    return res.status(error.statusCode).json({
      message: error.message,
      details: error.details ?? null
    });
  }

  console.error('[unhandled]', error);
  return res.status(500).json({
    message: 'Internal server error.'
  });
};
