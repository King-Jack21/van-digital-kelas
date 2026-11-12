'use server';

import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';

type AuthActionState = { error?: string; success?: string };

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  fullName: z.string().min(2).max(80).optional(),
});

export async function signIn(_prevState: AuthActionState, formData: FormData): Promise<AuthActionState> {
  const parsed = schema.pick({ email: true, password: true }).safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: 'Email atau password tidak valid.' };

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);
  if (error) return { error: 'Tidak dapat masuk. Periksa kredensial Anda.' };

  redirect('/dashboard');
}

export async function signUp(_prevState: AuthActionState, formData: FormData): Promise<AuthActionState> {
  const parsed = schema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: 'Lengkapi nama, email, dan password minimal 8 karakter.' };

  const supabase = await createClient();
  const { error } = await supabase.auth.signUp({
    email: parsed.data.email,
    password: parsed.data.password,
    options: { data: { full_name: parsed.data.fullName } },
  });
  if (error) return { error: 'Pendaftaran gagal. Periksa kembali data dan coba lagi.' };
  return { success: 'Akun dibuat. Periksa email Anda untuk verifikasi.' };
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect('/login');
}
