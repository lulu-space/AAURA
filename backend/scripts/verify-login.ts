/**
 * Verify Supabase password login returns an access_token.
 * Usage: STUDENT_TEST_EMAIL=... SET_PASSWORD_VALUE=... npx tsx scripts/verify-login.ts
 */
import dotenv from 'dotenv';

dotenv.config();

const url = process.env.SUPABASE_URL?.replace(/\/$/, '');
const anonKey = process.env.SUPABASE_ANON_KEY;
const email = process.env.STUDENT_TEST_EMAIL ?? 'l.diab1@student.aaup.edu';
const password = process.env.SET_PASSWORD_VALUE;

if (!url || !anonKey || !password) {
  console.error('Need SUPABASE_URL, SUPABASE_ANON_KEY, and SET_PASSWORD_VALUE in env');
  process.exit(1);
}

const res = await fetch(`${url}/auth/v1/token?grant_type=password`, {
  method: 'POST',
  headers: {
    apikey: anonKey,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ email, password })
});

const body = await res.json().catch(() => ({}));

if (!res.ok) {
  console.error('Login failed:', res.status, body);
  process.exit(1);
}

if (body.access_token) {
  console.log('Login OK — access_token received for', email);
  console.log('user id:', body.user?.id ?? '(see user object)');
  process.exit(0);
}

console.error('No access_token in response:', body);
process.exit(1);
