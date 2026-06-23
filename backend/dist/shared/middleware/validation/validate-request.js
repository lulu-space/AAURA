import { ApiError } from '../../../core/errors/api-error.js';
export const validateRequest = (schema) => (req, _res, next) => {
    const result = schema.safeParse({
        body: req.body,
        params: req.params,
        query: req.query
    });
    if (!result.success) {
        return next(new ApiError(400, 'Validation failed.', result.error.flatten()));
    }
    const { body, params, query } = result.data;
    req.body = body;
    req.params = params;
    // In some runtimes/adapters `req.query` is a getter-only property; avoid direct assignment.
    // Prefer merging into the existing query object when possible, and also expose a stable field.
    req.validatedQuery = query;
    if (req.query && typeof req.query === 'object' && query && typeof query === 'object') {
        Object.assign(req.query, query);
    }
    next();
};
