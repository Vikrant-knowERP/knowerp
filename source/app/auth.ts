import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

const AUTH_COOKIE = 'knowerp_auth';
const AUTH_PASSWORD = process.env.APP_PASSWORD || 'password123';

export async function isAuthenticated(): Promise<boolean> {
  const cookieStore = await cookies();
  const auth = cookieStore.get(AUTH_COOKIE)?.value;
  return auth === 'true';
}

export async function requireAuth(returnTo: string = '/'): Promise<void> {
  const authenticated = await isAuthenticated();
  if (!authenticated) {
    redirect(`/login?returnTo=${encodeURIComponent(returnTo)}`);
  }
}

export async function loginWithPassword(password: string): Promise<boolean> {
  if (password === AUTH_PASSWORD) {
    const cookieStore = await cookies();
    cookieStore.set(AUTH_COOKIE, 'true', {
      maxAge: 60 * 60 * 24 * 365, // 1 year
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
    });
    return true;
  }
  return false;
}

export async function logout(): Promise<void> {
  const cookieStore = await cookies();
  cookieStore.delete(AUTH_COOKIE);
  redirect('/login');
}
