import { Navigate, Route, Routes } from 'react-router-dom';
import { AppLayout } from './components/AppLayout';
import { ProtectedRoute } from './components/ProtectedRoute';
import { ForgotPasswordPage, LoginPage, RegisterPage } from './pages/AuthPages';
import { AnnouncementDetailPage, AnnouncementsPage, BookingPage, CatalogPage, DashboardPage, LoansPage, MyBookingsPage, NewLoanPage, NotificationsPage, ProfilePage, ReportsPage, SchedulePage } from './pages/StudentPages';
import { AdminAnalyticsPage, AdminApplicationsPage, AdminAnnouncementsPage, AdminBookingsPage, AdminDashboardPage, AdminInventoryPage, AdminLoansPage, AdminReportsPage, AdminRoomsPage, AdminUsersPage, StaffAttendancePage, StaffDashboardPage, StaffLoansPage, StaffReportsPage, StaffSchedulePage } from './pages/AdminStaffPages';

export function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />
      <Route element={<ProtectedRoute roles={['STUDENT', 'LECTURER']} />}>
        <Route element={<AppLayout />}>
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/katalog" element={<CatalogPage />} />
          <Route path="/peminjaman/baru" element={<NewLoanPage />} />
          <Route path="/peminjaman" element={<LoansPage />} />
          <Route path="/reservasi" element={<BookingPage />} />
          <Route path="/reservasi/saya" element={<MyBookingsPage />} />
          <Route path="/jadwal" element={<SchedulePage />} />
          <Route path="/pengumuman" element={<AnnouncementsPage />} />
          <Route path="/pengumuman/:id" element={<AnnouncementDetailPage />} />
          <Route path="/laporan" element={<ReportsPage />} />
          <Route path="/notifikasi" element={<NotificationsPage />} />
          <Route path="/profil" element={<ProfilePage />} />
        </Route>
      </Route>
      <Route element={<ProtectedRoute roles={['STAFF', 'ADMIN']} />}>
        <Route element={<AppLayout />}>
          <Route path="/staff/dashboard" element={<StaffDashboardPage />} />
          <Route path="/staff/jadwal-piket" element={<StaffSchedulePage />} />
          <Route path="/staff/absensi" element={<StaffAttendancePage />} />
          <Route path="/staff/peminjaman" element={<StaffLoansPage />} />
          <Route path="/staff/laporan-kerusakan" element={<StaffReportsPage />} />
        </Route>
      </Route>
      <Route element={<ProtectedRoute roles={['ADMIN']} />}>
        <Route element={<AppLayout />}>
          <Route path="/admin/dashboard" element={<AdminDashboardPage />} />
          <Route path="/admin/peminjaman" element={<AdminLoansPage />} />
          <Route path="/admin/reservasi" element={<AdminBookingsPage />} />
          <Route path="/admin/inventaris" element={<AdminInventoryPage />} />
          <Route path="/admin/ruangan" element={<AdminRoomsPage />} />
          <Route path="/admin/pengumuman" element={<AdminAnnouncementsPage />} />
          <Route path="/admin/pengguna" element={<AdminUsersPage />} />
          <Route path="/admin/laporan-rusak" element={<AdminReportsPage />} />
          <Route path="/admin/staff-applications" element={<AdminApplicationsPage />} />
          <Route path="/admin/analitik" element={<AdminAnalyticsPage />} />
        </Route>
      </Route>
      <Route path="/unauthorized" element={<div className="grid min-h-screen place-items-center text-3xl font-black">403 Unauthorized</div>} />
    </Routes>
  );
}
