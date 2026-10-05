import { cookies } from 'next/headers';

const AUTH_COOKIE = 'knowerp_auth';
const AUTH_PASSWORD = process.env.APP_PASSWORD || 'password123';

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { password } = body;

    if (password === AUTH_PASSWORD) {
      const cookieStore = await cookies();
      cookieStore.set(AUTH_COOKIE, 'true', {
        maxAge: 60 * 60 * 24 * 365, // 1 year
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
      });

      return Response.json({ success: true });
    }

    return Response.json({ error: 'Invalid password' }, { status: 401 });
  } catch (error) {
    return Response.json({ error: 'Login failed' }, { status: 500 });
  }
}
