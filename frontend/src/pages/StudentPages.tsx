import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { format, formatDistanceToNow } from 'date-fns';
import { id } from 'date-fns/locale';
import { CalendarDays, ClipboardList, Megaphone, Plus, Search, Wrench } from 'lucide-react';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import toast from 'react-hot-toast';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { api } from '../api/axios';
import { useApiList, useEquipment, useUnreadCount } from '../api/hooks';
import { EmptyState } from '../components/EmptyState';
import { StatusBadge } from '../components/StatusBadge';
import { useAuthStore } from '../stores/authStore';
import type { ApiResponse, Equipment } from '../types';

export function DashboardPage() {
  const user = useAuthStore((s) => s.user);
  const activeLoans = useApiList<any>(['loans-active'], '/loans/my/active');
  const bookings = useApiList<any>(['bookings-upcoming'], '/bookings/my/upcoming');
  const announcements = useApiList<any>(['announcements-home'], '/announcements?limit=3');
  const unread = useUnreadCount();
  return (
    <div className="space-y-6">
      <section className="rounded-lg bg-gradient-to-br from-primary via-indigoLive to-cyanLive p-6 text-white shadow-labin">
        <h2 className="text-3xl font-black">Halo, {user?.name}! 👋</h2>
        <p className="text-white/75">{format(new Date(), 'EEEE, dd MMMM yyyy', { locale: id })}</p>
        <div className="mt-5 flex flex-wrap gap-3">
          <Chip label={`${activeLoans.data?.data.length ?? 0} Peminjaman Aktif`} />
          <Chip label={`${bookings.data?.data.length ?? 0} Reservasi Aktif`} />
          <Chip label={`${unread.data?.count ?? 0} Notif Belum Dibaca`} />
        </div>
      </section>
      <div className="grid gap-4 md:grid-cols-4">
        <Quick to="/katalog" icon={<ClipboardList />} title="Pinjam Alat" />
        <Quick to="/reservasi" icon={<CalendarDays />} title="Reservasi" />
        <Quick to="/laporan" icon={<Wrench />} title="Laporan Kerusakan" />
        <Quick to="/pengumuman" icon={<Megaphone />} title="Pengumuman" />
      </div>
      <Section title="Status Aktif">{activeLoans.data?.data.length ? activeLoans.data.data.map((loan: any) => <LoanCard key={loan.id} loan={loan} />) : <EmptyState title="Belum ada peminjaman aktif." />}</Section>
      <Section title="Upcoming Bookings">{bookings.data?.data.map((b: any) => <div className="card p-4" key={b.id}><b>{b.room.name}</b><p>{format(new Date(b.date), 'dd MMM yyyy')} {b.startTime}-{b.endTime}</p><StatusBadge value={b.status}/></div>)}</Section>
      <Section title="Recent Announcements">{announcements.data?.data.map((a: any) => <Link to={`/pengumuman/${a.id}`} className="card block p-4" key={a.id}><b>{a.isPinned ? '📌 ' : ''}{a.title}</b><p className="text-sm text-slate-500">{a.content.slice(0, 120)}...</p></Link>)}</Section>
    </div>
  );
}

export function CatalogPage() {
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('');
  const [available, setAvailable] = useState(false);
  const qs = `?limit=10${search ? `&search=${search}` : ''}${category ? `&category=${category}` : ''}${available ? '&available=true' : ''}`;
  const equipment = useEquipment(qs);
  return (
    <div className="space-y-4">
      <div className="card flex flex-wrap gap-3 p-4"><div className="relative flex-1"><Search className="absolute left-3 top-2.5" size={18}/><input className="input pl-10" placeholder="Cari alat..." onChange={(e) => setSearch(e.target.value)} /></div><select className="input max-w-56" onChange={(e) => setCategory(e.target.value)}><option value="">Semua</option>{['COMPUTER','STUDIO','NETWORK','MULTIMEDIA','ELECTRONICS','MEASUREMENT'].map(c => <option key={c}>{c}</option>)}</select><label className="flex items-center gap-2 text-sm font-bold"><input type="checkbox" onChange={(e) => setAvailable(e.target.checked)} /> Tersedia saja</label></div>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">{equipment.data?.data.map((item) => <EquipmentCard key={item.id} item={item} />)}</div>
    </div>
  );
}

export function NewLoanPage() {
  const [params] = useSearchParams();
  const equipment = useEquipment('?available=true&limit=100');
  const { register, handleSubmit, watch } = useForm<any>({ defaultValues: { equipmentId: params.get('equipmentId') ?? '', quantity: 1 } });
  const navigate = useNavigate();
  async function submit(values: any) {
    const form = new FormData();
    Object.entries(values).forEach(([k, v]) => form.append(k, String(v)));
    await api.post('/loans', form);
    toast.success('Permohonan terkirim');
    navigate('/peminjaman');
  }
  return <form onSubmit={handleSubmit(submit)} className="card max-w-3xl space-y-4 p-6"><h2 className="text-2xl font-black">Peminjaman Baru</h2><select className="input" {...register('equipmentId')}><option value="">Pilih alat</option>{equipment.data?.data.map((e) => <option value={e.id} key={e.id}>{e.name} ({e.availableStock} tersedia)</option>)}</select><input className="input" type="number" min={1} {...register('quantity')} /><input className="input" type="date" {...register('borrowDate')} /><input className="input" type="date" {...register('returnDate')} /><textarea className="input min-h-28" placeholder="Keperluan minimal 20 karakter" {...register('purpose')} /><input className="input" type="file" name="document" /><button className="btn-primary">Kirim Permohonan</button></form>;
}

export function LoansPage() {
  const qc = useQueryClient();
  const loans = useApiList<any>(['loans'], '/loans?limit=20');
  const cancel = useMutation({ mutationFn: (id: string) => api.put(`/loans/${id}/cancel`), onSuccess: () => { toast.success('Peminjaman dibatalkan'); qc.invalidateQueries({ queryKey: ['loans'] }); } });
  return <Section title="Peminjaman Saya">{loans.data?.data.map((loan: any) => <LoanCard key={loan.id} loan={loan} onCancel={() => cancel.mutate(loan.id)} />)}</Section>;
}

export function BookingPage() {
  const rooms = useApiList<any>(['rooms'], '/rooms');
  const { register, handleSubmit, watch } = useForm<any>();
  const qc = useQueryClient();
  const slots = useApiList<any>(['slots', watch('roomId'), watch('date')], watch('roomId') && watch('date') ? `/bookings/room/${watch('roomId')}/slots?date=${watch('date')}` : '/bookings/room/00000000-0000-0000-0000-000000000000/slots?date=2026-01-01');
  async function submit(values: any) { await api.post('/bookings', values); toast.success('Reservasi dibuat'); qc.invalidateQueries(); }
  return <div className="grid gap-4 xl:grid-cols-2"><div className="space-y-3">{rooms.data?.data.map((r: any) => <div className="card p-4" key={r.id}><b>{r.name}</b><p>{r.capacity} kursi • {r.facilities.join(', ')}</p></div>)}</div><form onSubmit={handleSubmit(submit)} className="card space-y-3 p-5"><select className="input" {...register('roomId')}>{rooms.data?.data.map((r: any) => <option value={r.id} key={r.id}>{r.name}</option>)}</select><input className="input" type="date" {...register('date')} /><div className="grid grid-cols-4 gap-2">{slots.data?.data.map((s: any) => <span className="rounded bg-red-100 p-2 text-xs text-red-700" key={s.id}>{s.startTime}-{s.endTime}</span>)}</div><input className="input" placeholder="Start 09:00" {...register('startTime')} /><input className="input" placeholder="End 11:00" {...register('endTime')} /><input className="input" placeholder="Nama kegiatan" {...register('activityName')} /><select className="input" {...register('activityType')}><option>PRACTICUM</option><option>LECTURE</option><option>RESEARCH</option><option>ORGANIZATION</option></select><input className="input" type="number" placeholder="Peserta" {...register('participants')} /><textarea className="input" placeholder="Catatan" {...register('notes')} /><button className="btn-primary">Pesan Ruangan</button></form></div>;
}

export function ReportsPage() {
  const reports = useApiList<any>(['reports'], '/reports');
  const { register, handleSubmit } = useForm<any>();
  async function submit(values: any) { await api.post('/reports', values); toast.success('Laporan dikirim'); }
  return <div className="grid gap-5 xl:grid-cols-2"><form onSubmit={handleSubmit(submit)} className="card space-y-3 p-5"><h2 className="font-black">Buat Laporan</h2><input className="input" placeholder="Lokasi" {...register('location')} /><input className="input" placeholder="Fasilitas" {...register('facilityName')} /><textarea className="input min-h-28" placeholder="Deskripsi minimal 30 karakter" {...register('description')} /><select className="input" {...register('urgency')}><option>LOW</option><option>MEDIUM</option><option>HIGH</option><option>CRITICAL</option></select><button className="btn-primary">Kirim Laporan</button></form><div>{reports.data?.data.map((r:any)=><div className="card mb-3 p-4" key={r.id}><b>{r.trackingId}</b><p>{r.location} • {r.facilityName}</p><StatusBadge value={r.status}/></div>)}</div></div>;
}

export function AnnouncementsPage() {
  const data = useApiList<any>(['announcements'], '/announcements?limit=20');
  return <Section title="Pengumuman">{data.data?.data.map((a:any)=><Link className="card block p-4" to={`/pengumuman/${a.id}`} key={a.id}><b>{a.isPinned ? '📌 ' : ''}{a.title}</b><p className="text-sm text-slate-500">{a.category} • {a.viewCount} views</p><p>{a.content.slice(0,150)}</p></Link>)}</Section>;
}

export function AnnouncementDetailPage() {
  return <RemoteDetail endpoint={location.pathname.replace('/pengumuman', '/announcements')} />;
}

export function NotificationsPage() {
  const qc = useQueryClient();
  const data = useApiList<any>(['notifications'], '/notifications');
  async function readAll(){ await api.put('/notifications/read-all'); qc.invalidateQueries(); }
  return <Section title="Notifikasi"><button className="btn-secondary mb-3" onClick={readAll}>Tandai Semua Dibaca</button>{data.data?.data.map((n:any)=><div className="card mb-3 p-4" key={n.id}><b>{n.title}</b><p>{n.message}</p><span className="text-xs text-slate-500">{formatDistanceToNow(new Date(n.createdAt), { addSuffix: true, locale: id })}</span></div>)}</Section>;
}

export function ProfilePage() {
  const user = useAuthStore((s) => s.user);
  const { register, handleSubmit } = useForm<any>({ defaultValues: user ?? {} });
  async function submit(values: any) { await api.put('/auth/me', values); toast.success('Profil disimpan'); }
  return <form onSubmit={handleSubmit(submit)} className="card max-w-2xl space-y-3 p-5"><h2 className="text-2xl font-black">Profil</h2><input className="input" {...register('name')} /><input className="input" disabled value={user?.email} /><input className="input" {...register('phone')} /><input className="input" {...register('university')} /><input className="input" {...register('faculty')} /><input className="input" {...register('studyProgram')} /><button className="btn-primary">Simpan</button></form>;
}

export function SchedulePage(){ return <BookingPage />; }
export function MyBookingsPage(){ const data=useApiList<any>(['my-bookings'],'/bookings?limit=20'); return <Section title="Reservasi Saya">{data.data?.data.map((b:any)=><div className="card mb-3 p-4" key={b.id}><b>{b.trackingId}</b><p>{b.room.name} • {b.date} • {b.startTime}-{b.endTime}</p><StatusBadge value={b.status}/></div>)}</Section>; }

function EquipmentCard({ item }: { item: Equipment }) {
  return <div className="card overflow-hidden"><div className="grid h-36 place-items-center bg-gradient-to-br from-primary to-cyanLive text-5xl text-white">⚗</div><div className="space-y-3 p-4"><b>{item.name}</b><p className="text-sm text-slate-500">{item.category}</p><p>{item.availableStock}/{item.totalStock} tersedia</p><Link className="btn-primary w-full" to={`/peminjaman/baru?equipmentId=${item.id}`}>Pinjam Sekarang</Link></div></div>;
}
function LoanCard({ loan, onCancel }: { loan: any; onCancel?: () => void }) { return <div className="card mb-3 p-4"><div className="flex items-center justify-between"><b>{loan.equipment?.name}</b><StatusBadge value={loan.status}/></div><p className="font-mono text-xs">{loan.trackingId}</p><p>{loan.borrowDate?.slice(0,10)} → {loan.returnDate?.slice(0,10)}</p>{loan.status === 'PENDING' && onCancel ? <button className="btn-secondary mt-3 text-danger" onClick={onCancel}>Batalkan</button> : null}</div>; }
function Quick({ to, icon, title }: { to: string; icon: React.ReactNode; title: string }) { return <Link to={to} className="card flex items-center gap-3 p-4 font-black">{icon}{title}</Link>; }
function Chip({ label }: { label: string }) { return <span className="rounded-full border border-white/20 bg-white/15 px-3 py-1 text-sm font-bold">{label}</span>; }
export function Section({ title, children }: { title: string; children: React.ReactNode }) { return <section className="space-y-3"><h2 className="text-xl font-black">{title}</h2>{children}</section>; }
function RemoteDetail({ endpoint }: { endpoint: string }) { const q=useQuery({queryKey:[endpoint],queryFn:async()=> (await api.get(endpoint)).data.data}); return <div className="card p-6"><h2 className="text-2xl font-black">{q.data?.title}</h2><p className="mt-4 whitespace-pre-wrap">{q.data?.content ?? JSON.stringify(q.data)}</p></div>; }
