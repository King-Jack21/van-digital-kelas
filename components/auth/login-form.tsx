'use client';

import Link from 'next/link';
import { useActionState } from 'react';
import { LockKeyhole } from 'lucide-react';
import { signIn } from '@/lib/actions/auth';

const initialState: { error?: string } = {};

export function LoginForm() {
  const [state, action, pending] = useActionState(signIn, initialState);

  return (
    <form action={action} className="auth-form">
      <label>Email<input type="email" name="email" required placeholder="nama@email.com" autoComplete="email" /></label>
      <label>Password<input type="password" name="password" minLength={8} required placeholder="Minimal 8 karakter" autoComplete="current-password" /></label>
      {state.error && <p className="form-error" role="alert">{state.error}</p>}
      <button className="primary-btn" type="submit" disabled={pending}>
        <LockKeyhole size={17} /> {pending ? 'Memproses...' : 'Masuk'}
      </button>
      <div className="auth-links"><Link href="/forgot-password">Lupa password?</Link><span>Belum punya akun? <Link href="/register">Daftar</Link></span></div>
    </form>
  );
}
