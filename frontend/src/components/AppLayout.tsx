import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { Bell, Boxes, CalendarDays, ChartPie, ClipboardList, Home, LogOut, Megaphone, Moon, User, Users, Wrench } from 'lucide-react';
import { api } from '../api/axios';
import { useUnreadCount } from '../api/hooks';
import { useAuthStore } from '../stores/authStore';

const studentLinks = [
  ['Dashboard', '/dashboard', Home],
  ['Katalog Alat', '/katalog', Boxes],
  ['Peminjaman Saya', '/peminjaman', ClipboardList],
  ['Reservasi Ruangan', '/reservasi', CalendarDays],
  ['Jadwal Lab', '/jadwal', CalendarDays],
  ['Pengumuman', '/pengumuman', Megaphone],
  ['Laporan Kerusakan', '/laporan', Wrench],
  ['Notifikasi', '/notifikasi', Bell],
  ['Profil', '/profil', User],
] as const;

const staffLinks = [
  ['Staff Dashboard', '/staff/dashboard', Home],
  ['Jadwal Piket', '/staff/jadwal-piket', CalendarDays],
  ['Absensi', '/staff/absensi', ClipboardList],
  ['Kelola Peminjaman', '/staff/peminjaman', Boxes],
  ['Laporan Kerusakan', '/staff/laporan-kerusakan', Wrench],
] as const;

const adminLinks = [
  ['Admin Dashboard', '/admin/dashboard', ChartPie],
  ['Peminjaman', '/admin/peminjaman', ClipboardList],
  ['Reservasi', '/admin/reservasi', CalendarDays],
  ['Inventaris', '/admin/inventaris', Boxes],
  ['Ruangan', '/admin/ruangan', Home],
  ['Pengumuman', '/admin/pengumuman', Megaphone],
  ['Pengguna', '/admin/pengguna', Users],
  ['Laporan Rusak', '/admin/laporan-rusak', Wrench],
  ['Analitik', '/admin/analitik', ChartPie],
] as const;

export function AppLayout() {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();
  const unread = useUnreadCount();
  const links = user?.role === 'ADMIN' ? adminLinks : user?.role === 'STAFF' ? staffLinks : studentLinks;

  async function doLogout() {
    await api.post('/auth/logout').catch(() => undefined);
    logout();
    navigate('/login');
  }

  return (
    <div className="min-h-screen lg:flex">
      <aside className="fixed inset-y-0 left-0 z-20 hidden w-72 border-r border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-slate-900 lg:block">
        <div className="mb-6 flex items-center gap-3">
          <div className="grid h-11 w-11 place-items-center rounded-lg bg-primary text-white">⚗</div>
          <div>
            <p className="text-xl font-black text-primary dark:text-white">Labin</p>
            <p className="text-xs text-slate-500">Lab Smarter, Not Harder</p>
          </div>
        </div>
        <nav className="space-y-1">
          {links.map(([label, href, Icon]) => (
            <NavLink key={href} to={href} className={({ isActive }) => `flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-bold ${isActive ? 'bg-indigoLive text-white' : 'text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800'}`}>
              <Icon size={18} />
              <span className="flex-1">{label}</span>
              {label === 'Notifikasi' && unread.data?.count ? <span className="rounded-full bg-cyanLive px-2 text-xs text-white">{unread.data.count}</span> : null}
            </NavLink>
          ))}
        </nav>
        <div className="absolute bottom-4 left-4 right-4 space-y-2">
          <button className="btn-secondary w-full" onClick={() => document.documentElement.classList.toggle('dark')}><Moon size={16} /> Mode Gelap</button>
          <button className="btn-secondary w-full text-danger" onClick={doLogout}><LogOut size={16} /> Logout</button>
        </div>
      </aside>
      <main className="min-w-0 flex-1 p-4 lg:ml-72 lg:p-8">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <p className="text-sm text-slate-500">Masuk sebagai {user?.role}</p>
            <h1 className="text-2xl font-black">{user?.name}</h1>
          </div>
          <NavLink to="/notifikasi" className="btn-secondary relative"><Bell size={18} />{unread.data?.count ? <span className="absolute -right-1 -top-1 h-5 min-w-5 rounded-full bg-cyanLive px-1 text-xs text-white">{unread.data.count}</span> : null}</NavLink>
        </div>
        <Outlet />
      </main>
    </div>
  );
}
