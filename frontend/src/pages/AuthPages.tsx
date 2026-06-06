import { zodResolver } from '@hookform/resolvers/zod';
import { Eye, FlaskConical } from 'lucide-react';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import toast from 'react-hot-toast';
import { Link, useNavigate } from 'react-router-dom';
import { z } from 'zod';
import { api } from '../api/axios';
import { useAuthStore } from '../stores/authStore';
import type { User } from '../types';

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(1) });
const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(8),
  confirmPassword: z.string(),
  nim: z.string().min(3),
  university: z.string().min(2),
  faculty: z.string().min(2),
  studyProgram: z.string().min(2),
  phone: z.string().optional(),
}).refine((data) => data.password === data.confirmPassword, { path: ['confirmPassword'], message: 'Password belum sama' });

function redirectFor(role: string) {
  if (role === 'ADMIN') return '/admin/dashboard';
  if (role === 'STAFF') return '/staff/dashboard';
  return '/dashboard';
}

export function LoginPage() {
  const [show, setShow] = useState(false);
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<z.infer<typeof loginSchema>>({ resolver: zodResolver(loginSchema) });

  async function submit(values: z.infer<typeof loginSchema>) {
    try {
      const { data } = await api.post('/auth/login', values);
      setAuth(data.data.user, data.data.accessToken);
      toast.success('Login berhasil');
      navigate(redirectFor(data.data.user.role));
    } catch (error: any) {
      toast.error(error.response?.data?.message ?? 'Login gagal');
    }
  }

  return (
    <AuthShell>
      <form onSubmit={handleSubmit(submit)} className="w-full max-w-md space-y-4">
        <div><h2 className="text-3xl font-black">Masuk</h2><p className="text-sm text-slate-500">Gunakan akun Labin kamu.</p></div>
        <Field label="Email" error={errors.email?.message}><input className="input" {...register('email')} /></Field>
        <Field label="Password" error={errors.password?.message}>
          <div className="relative"><input className="input pr-10" type={show ? 'text' : 'password'} {...register('password')} /><button type="button" onClick={() => setShow(!show)} className="absolute right-3 top-2.5"><Eye size={18}/></button></div>
        </Field>
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" /> Remember me</label>
        <button className="btn-primary w-full" disabled={isSubmitting}>{isSubmitting ? 'Masuk...' : 'Login'}</button>
        <div className="flex justify-between text-sm"><Link className="font-bold text-indigoLive" to="/register">Daftar</Link><Link className="font-bold text-indigoLive" to="/forgot-password">Lupa password?</Link></div>
      </form>
    </AuthShell>
  );
}

export function RegisterPage() {
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);
  const { register, handleSubmit, watch, formState: { errors, isSubmitting } } = useForm<z.infer<typeof registerSchema>>({ resolver: zodResolver(registerSchema) });
  const strength = Math.min(100, (watch('password')?.length ?? 0) * 12);

  async function submit(values: z.infer<typeof registerSchema>) {
    const { confirmPassword, ...payload } = values;
    try {
      const { data } = await api.post('/auth/register', payload);
      setAuth(data.data.user, data.data.accessToken);
      toast.success('Akun dibuat');
      navigate('/dashboard');
    } catch (error: any) {
      toast.error(error.response?.data?.message ?? 'Register gagal');
    }
  }

  return (
    <AuthShell>
      <form onSubmit={handleSubmit(submit)} className="grid w-full max-w-2xl gap-4 md:grid-cols-2">
        <div className="md:col-span-2"><h2 className="text-3xl font-black">Daftar Akun</h2><p className="text-sm text-slate-500">Semua data tersimpan di backend.</p></div>
        {(['name','email','nim','university','faculty','studyProgram','phone'] as const).map((name) => <Field key={name} label={name} error={errors[name]?.message as string}><input className="input" {...register(name)} /></Field>)}
        <Field label="Password" error={errors.password?.message}><input className="input" type="password" {...register('password')} /><div className="mt-2 h-2 rounded bg-slate-100"><div className="h-2 rounded bg-gradient-to-r from-danger via-warning to-success" style={{ width: `${strength}%` }} /></div></Field>
        <Field label="Confirm Password" error={errors.confirmPassword?.message}><input className="input" type="password" {...register('confirmPassword')} /></Field>
        <button className="btn-primary md:col-span-2" disabled={isSubmitting}>{isSubmitting ? 'Mendaftarkan...' : 'Daftar Sekarang'}</button>
      </form>
    </AuthShell>
  );
}

export function ForgotPasswordPage() {
  const { register, handleSubmit } = useForm<{ email: string }>();
  async function submit(values: { email: string }) {
    await api.post('/auth/forgot-password', values);
    toast.success('Cek email kamu. Link reset valid 15 menit.');
  }
  return <AuthShell><form onSubmit={handleSubmit(submit)} className="w-full max-w-md space-y-4"><h2 className="text-3xl font-black">Lupa Password</h2><input className="input" placeholder="Email" {...register('email')} /><button className="btn-primary w-full">Kirim Link Reset</button></form></AuthShell>;
}

function AuthShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="grid min-h-screen md:grid-cols-2">
      <section className="hidden bg-gradient-to-br from-primary via-indigoLive to-cyanLive p-10 text-white md:flex md:flex-col md:justify-between">
        <div className="flex items-center gap-3"><div className="rounded-lg bg-white/15 p-3"><FlaskConical /></div><div><p className="text-3xl font-black">Labin</p><p>Lab Smarter, Not Harder</p></div></div>
        <div className="space-y-4 text-lg font-semibold"><p>✓ Peminjaman alat real-time</p><p>✓ Reservasi ruangan tanpa bentrok</p><p>✓ Tracking dan notifikasi otomatis</p></div>
      </section>
      <section className="flex items-center justify-center p-6">{children}</section>
    </div>
  );
}

function Field({ label, error, children }: { label: string; error?: string; children: React.ReactNode }) {
  return <label className="space-y-1 text-sm font-bold capitalize">{label}{children}{error ? <p className="text-xs text-danger">{error}</p> : null}</label>;
}
