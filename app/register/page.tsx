import Link from 'next/link';
import { GraduationCap } from 'lucide-react';
import { RegisterForm } from '@/components/auth/register-form';

export default function Register() {
  return (
    <main className="auth-page">
      <div className="auth-card">
        <Link className="brand auth-brand" href="/">
          <span className="brand-mark"><GraduationCap /></span>
          <span><b>VAN<br />Classroom</b><small>Learn · Manage · Grow</small></span>
        </Link>
        <p className="eyebrow">GET STARTED</p>
        <h1>Buat akun baru.</h1>
        <p className="muted">Pendaftaran publik secara default membuat akun student.</p>
        <RegisterForm />
      </div>
    </main>
  );
}
