import { z } from 'zod';
export const purchaseShopItemSchema = z.object({
    body: z.object({ item_id: z.string().min(3) }),
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
