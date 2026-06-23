/**
 * One-off admin utility: set a Supabase Auth user's password.
 * Usage (from backend/):
 *   SET_PASSWORD_USER_ID=<uuid> SET_PASSWORD_VALUE=<password> npx tsx scripts/set-password.ts
 * Or add SET_PASSWORD_USER_ID and SET_PASSWORD_VALUE to .env (do not commit passwords).
 */
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const userId = process.env.SET_PASSWORD_USER_ID;
const newPassword = process.env.SET_PASSWORD_VALUE;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}

if (!userId || !newPassword) {
  console.error('Missing SET_PASSWORD_USER_ID or SET_PASSWORD_VALUE');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
});

const { data, error } = await supabase.auth.admin.updateUserById(userId, {
  password: newPassword
});

if (error) {
  console.error('Failed to update password:', error.message);
  process.exit(1);
}

console.log('✅ Password updated:', data.user?.id ?? userId);
