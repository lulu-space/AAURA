import dotenv from 'dotenv';
import { z } from 'zod';
dotenv.config();
const envSchema = z.object({
    PORT: z.coerce.number().default(4000),
    SUPABASE_URL: z.string().url(),
    SUPABASE_ANON_KEY: z.string().min(1),
    SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
    JWT_AUDIENCE: z.string().default('authenticated'),
    AI_SERVICE_URL: z.string().url().default('http://localhost:8000')
});
export const env = envSchema.parse(process.env);
