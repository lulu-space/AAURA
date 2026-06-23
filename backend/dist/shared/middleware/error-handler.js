import { ApiError } from '../../core/errors/api-error.js';
export const errorHandler = (error, _req, res, _next) => {
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
