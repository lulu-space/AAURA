import type { NextFunction, Request, Response } from 'express';
import type { ZodTypeAny } from 'zod';
import { ApiError } from '../../../core/errors/api-error.js';

export const validateRequest =
  (schema: ZodTypeAny) => (req: Request, _res: Response, next: NextFunction) => {
    const result = schema.safeParse({
      body: req.body,
      params: req.params,
      query: req.query
    });

    if (!result.success) {
      return next(new ApiError(400, 'Validation failed.', result.error.flatten()));
    }

    const { body, params, query } = result.data as {
      body: Request['body'];
      params: Request['params'];
      query: Request['query'];
    };
    req.body = body;
    req.params = params;
    // In some runtimes/adapters `req.query` is a getter-only property; avoid direct assignment.
    // Prefer merging into the existing query object when possible, and also expose a stable field.
    (req as Request & { validatedQuery?: Request['query'] }).validatedQuery = query;
    if (req.query && typeof req.query === 'object' && query && typeof query === 'object') {
      Object.assign(req.query as Record<string, unknown>, query as Record<string, unknown>);
    }
    next();
  };
