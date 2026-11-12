'use client';

import Link from 'next/link';
import { useActionState } from 'react';
import { signUp } from '@/lib/actions/auth';

const initialState: { error?: string; success?: string } = {};

export function RegisterForm() {
  const [state, action, pending] = useActionState(signUp, initialState);

  return (
    <form action={action} className="auth-form">
      <label>Nama lengkap<input name="fullName" minLength={2} required placeholder="Nama Anda" autoComplete="name" /></label>
      <label>Email<input type="email" name="email" required placeholder="nama@email.com" autoComplete="email" /></label>
      <label>Password<input type="password" name="password" minLength={8} required placeholder="Minimal 8 karakter" autoComplete="new-password" /></label>
      {state.error && <p className="form-error" role="alert">{state.error}</p>}
      {state.success && <p className="form-success" role="status">{state.success}</p>}
      <button className="primary-btn" disabled={pending}>{pending ? 'Membuat akun...' : 'Buat akun'}</button>
      <div className="auth-links"><span>Sudah punya akun? <Link href="/login">Masuk</Link></span></div>
    </form>
  );
}
