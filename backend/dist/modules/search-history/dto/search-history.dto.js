import { z } from 'zod';
const searchHistoryBody = z.object({
    query: z.string().min(1),
    filters: z.record(z.string(), z.unknown()).default({})
});
export const createSearchHistorySchema = z.object({
    body: searchHistoryBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateSearchHistorySchema = z.object({
    body: searchHistoryBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
