import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';
import type { Role } from '@/types/database';
export async function getUserContext() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { supabase, user: null, profile: null };
  const { data: profile } = await supabase.from('profiles').select('*').eq('id', user.id).maybeSingle();
  return { supabase, user, profile };
}
export async function requireRole(roles: Role[]) {
  const ctx = await getUserContext();
  if (!ctx.user) redirect('/login');
  if (!ctx.profile || !roles.includes(ctx.profile.role)) redirect('/dashboard');
  return ctx as typeof ctx & { user: NonNullable<typeof ctx.user>; profile: NonNullable<typeof ctx.profile> };
}
