import Link from 'next/link';
import { GraduationCap } from 'lucide-react';
import { LoginForm } from '@/components/auth/login-form';

export default function Login() {
  return (
    <main className="auth-page">
      <div className="auth-card">
        <Link className="brand auth-brand" href="/">
          <span className="brand-mark"><GraduationCap /></span>
          <span><b>VAN<br />Classroom</b><small>Learn · Manage · Grow</small></span>
        </Link>
        <p className="eyebrow">WELCOME BACK</p>
        <h1>Masuk ke ruang belajar.</h1>
        <p className="muted">Lanjutkan perjalanan belajar dan mengajar Anda.</p>
        <LoginForm />
      </div>
    </main>
  );
}
