import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { api } from '../api/axios';
import { useApiList } from '../api/hooks';
import { Section } from './StudentPages';
import { StatusBadge } from '../components/StatusBadge';

export function StaffDashboardPage() {
  const shifts = useApiList<any>(['my-shifts'], '/staff/my-shifts');
  async function check(id: string, type: 'checkin'|'checkout') {
    await api.post(`/staff/shifts/${id}/${type}`);
    toast.success(type === 'checkin' ? 'Absen masuk dicatat' : 'Absen pulang dicatat');
  }
  return <Section title="Staff Dashboard">{shifts.data?.data.map((s:any)=><div className="card mb-3 p-4" key={s.id}><b>{s.room.name}</b><p>{s.date.slice(0,10)} • {s.startTime}-{s.endTime}</p><div className="mt-3 flex gap-2"><button className="btn-primary" onClick={()=>check(s.id,'checkin')}>Absen Masuk</button><button className="btn-secondary" onClick={()=>check(s.id,'checkout')}>Absen Pulang</button></div></div>)}</Section>;
}

export function StaffLoansPage() {
  const qc = useQueryClient();
  const loans = useApiList<any>(['staff-loans'], '/loans?limit=50');
  const action = useMutation({ mutationFn: ({id,type}:{id:string;type:string}) => api.put(`/loans/${id}/${type}`, type==='reject'?{adminNote:'Tidak memenuhi syarat'}:{}), onSuccess:()=>{toast.success('Status diperbarui'); qc.invalidateQueries();} });
  return <Section title="Kelola Peminjaman">{loans.data?.data.map((l:any)=><div className="card mb-3 p-4" key={l.id}><div className="flex justify-between"><b>{l.user.name} • {l.equipment.name}</b><StatusBadge value={l.status}/></div><div className="mt-3 flex flex-wrap gap-2"><button className="btn-primary" onClick={()=>action.mutate({id:l.id,type:'approve'})}>Setujui</button><button className="btn-secondary" onClick={()=>action.mutate({id:l.id,type:'reject'})}>Tolak</button><button className="btn-secondary" onClick={()=>action.mutate({id:l.id,type:'take'})}>Serahkan</button><button className="btn-secondary" onClick={()=>action.mutate({id:l.id,type:'return'})}>Terima Kembali</button></div></div>)}</Section>;
}

export function StaffReportsPage() {
  const qc = useQueryClient();
  const reports = useApiList<any>(['staff-reports'], '/reports?limit=50');
  async function update(id: string, status: string) { await api.put(`/reports/${id}/status`, { status, technicianNote: 'Diproses teknisi lab.' }); toast.success('Laporan diperbarui'); qc.invalidateQueries(); }
  return <Section title="Laporan Kerusakan">{reports.data?.data.map((r:any)=><div className="card mb-3 p-4" key={r.id}><b>{r.trackingId} • {r.facilityName}</b><p>{r.location}</p><StatusBadge value={r.status}/><div className="mt-3 flex gap-2"><button className="btn-secondary" onClick={()=>update(r.id,'IN_PROGRESS')}>Proses</button><button className="btn-primary" onClick={()=>update(r.id,'RESOLVED')}>Selesai</button></div></div>)}</Section>;
}

export function StaffAttendancePage(){ const data=useApiList<any>(['attendance'],'/staff/attendance'); return <Section title="Absensi">{data.data?.data.map((a:any)=><div className="card mb-3 p-4" key={a.id}><b>{a.shift.room.name}</b><p>Masuk: {a.checkIn ?? '-'} • Pulang: {a.checkOut ?? '-'}</p></div>)}</Section>; }
export function StaffSchedulePage(){ const data=useApiList<any>(['staff-shifts'],'/staff/shifts'); return <Section title="Jadwal Piket">{data.data?.data.map((s:any)=><div className="card mb-3 p-4" key={s.id}><b>{s.user.name}</b><p>{s.room.name} • {s.date.slice(0,10)} • {s.startTime}-{s.endTime}</p></div>)}</Section>; }

export function AdminDashboardPage() {
  const data = useQuery({ queryKey: ['admin-dashboard'], queryFn: async () => (await api.get('/admin/dashboard')).data });
  const d = data.data?.data as Record<string, any> | undefined;
  return <div className="space-y-6"><div className="grid gap-4 md:grid-cols-5">{['todayLoans','pendingLoans','todayBookings','totalEquipment','unresolvedReports'].map(k=><div className="card p-4" key={k}><p className="text-xs text-slate-500">{k}</p><b className="text-3xl">{d?.[k] ?? 0}</b></div>)}</div><pre className="card overflow-auto p-4 text-xs">{JSON.stringify(d?.loansByStatus, null, 2)}</pre></div>;
}

export function AdminUsersPage() {
  const qc = useQueryClient();
  const users = useApiList<any>(['admin-users'], '/admin/users?limit=50');
  async function role(id:string, value:string){ await api.put(`/admin/users/${id}/role`, { role:value }); qc.invalidateQueries(); }
  async function status(id:string, value:boolean){ await api.put(`/admin/users/${id}/status`, { isActive:value }); qc.invalidateQueries(); }
  return <Section title="Pengguna">{users.data?.data.map((u:any)=><div className="card mb-3 grid gap-3 p-4 md:grid-cols-6" key={u.id}><b>{u.name}</b><span>{u.email}</span><select className="input" value={u.role} onChange={e=>role(u.id,e.target.value)}><option>STUDENT</option><option>LECTURER</option><option>STAFF</option><option>ADMIN</option></select><span>{u.isActive?'Aktif':'Nonaktif'}</span><button className="btn-secondary" onClick={()=>status(u.id,!u.isActive)}>{u.isActive?'Nonaktifkan':'Aktifkan'}</button></div>)}</Section>;
}

export function AdminInventoryPage(){ return <CrudList title="Inventaris" endpoint="/equipment?limit=50" fields={['name','category','availableStock','totalStock','condition']} />; }
export function AdminRoomsPage(){ return <CrudList title="Ruangan" endpoint="/rooms" fields={['name','code','capacity','building','floor']} />; }
export function AdminAnnouncementsPage(){ return <CrudList title="Pengumuman" endpoint="/announcements?limit=50" fields={['title','category','isPublished','isPinned','viewCount']} />; }
export function AdminBookingsPage(){ return <CrudList title="Reservasi" endpoint="/bookings?limit=50" fields={['trackingId','activityName','status','date','startTime','endTime']} />; }
export function AdminLoansPage(){ return <StaffLoansPage />; }
export function AdminReportsPage(){ return <StaffReportsPage />; }
export function AdminApplicationsPage(){ return <CrudList title="Staff Applications" endpoint="/staff/applications" fields={['motivation','availability','status','createdAt']} />; }
export function AdminAnalyticsPage(){ const data=useApiList<any>(['analytics'],'/admin/analytics?period=month'); return <pre className="card overflow-auto p-5 text-xs">{JSON.stringify(data.data?.data,null,2)}</pre>; }

function CrudList({ title, endpoint, fields }: { title:string; endpoint:string; fields:string[] }) {
  const data = useApiList<any>([title, endpoint], endpoint);
  return <Section title={title}><div className="card overflow-auto"><table className="w-full text-left text-sm"><thead><tr>{fields.map(f=><th className="p-3" key={f}>{f}</th>)}</tr></thead><tbody>{data.data?.data.map((row:any)=><tr className="border-t border-slate-100" key={row.id}>{fields.map(f=><td className="p-3" key={f}>{String(row[f] ?? '')}</td>)}</tr>)}</tbody></table></div></Section>;
}
