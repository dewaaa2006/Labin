# Labin

Smart Laboratory Management System.

Repo ini berisi:

- Flutter mobile prototype di root `lib/`
- Full-stack web app di `backend/` dan `frontend/`

## Full-Stack Web App

Stack:

- Backend: Node.js 20, TypeScript, Express, Prisma, PostgreSQL, JWT auth, Multer uploads.
- Frontend: React 18, Vite, TypeScript, Tailwind, Zustand, TanStack Query, Axios.

### 1. Install

```powershell
npm install
npm install --prefix backend
npm install --prefix frontend
```

### 2. Env

Copy env:

```powershell
Copy-Item backend\.env.example backend\.env
Copy-Item frontend\.env.example frontend\.env
```

Isi `backend/.env`:

```text
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/labin_db"
JWT_ACCESS_SECRET="change-me"
JWT_REFRESH_SECRET="change-me-too"
```

### 3. Database

Pastikan PostgreSQL jalan dan database `labin_db` sudah ada, lalu:

```powershell
npm run prisma:migrate --prefix backend
npm run seed
```

Seed login:

```text
admin@labin.id / Admin123!
staff1@labin.id / Staff123!
mahasiswa1@labin.id / Mhs123!
```

### 4. Run

```powershell
npm run dev
```

Backend: `http://localhost:3001`

Frontend: `http://localhost:5173`

### 5. Build

```powershell
npm run build
```

### Full-Stack Features

- Register, login, refresh token, logout, forgot/reset password
- Role guard backend dan frontend: STUDENT, LECTURER, STAFF, ADMIN
- Equipment catalog, admin inventory
- Loan request, approve/reject/take/return/cancel
- Room booking with conflict validation
- Announcements with broadcast notification
- Damage reports with staff status update
- In-app notifications
- Staff shifts and attendance
- Admin dashboard, users, analytics, CSV export
- File upload to `backend/uploads`

## Flutter Mobile Prototype

## Run tanpa Supabase

```powershell
flutter run
```

UI tetap bisa dibuka sampai halaman login, tetapi login/register real akan ditolak sampai Supabase dikonfigurasi.

## Run dengan Supabase

Ambil Project URL dan publishable key dari Supabase Dashboard:

Project Settings -> API -> Project URL dan publishable key.

Lalu jalankan:

```powershell
flutter run `
  --dart-define=LABIN_SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=LABIN_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Untuk build APK debug:

```powershell
flutter build apk --debug `
  --dart-define=LABIN_SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=LABIN_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Env lama `LABIN_SUPABASE_ANON_KEY` juga masih diterima sebagai fallback.

## Supabase Auth

Yang sudah tersambung:

- Email/password login
- Email/password register
- User metadata saat register: name, nim, university, faculty, study_program, role
- Google OAuth trigger
- Logout real dari Supabase

Untuk Google OAuth, aktifkan provider Google di Supabase Auth dan tambahkan redirect URL:

```text
io.supabase.labin://login-callback/
```

## Backend Database

Backend lengkap ada di folder:

```text
supabase/
```

Isi penting:

- `supabase/migrations/202606060001_initial_labin_backend.sql`: schema, enum, trigger, RLS policy, storage bucket.
- `supabase/seed.sql`: data awal lab, ruangan, kategori, alat, dan pengumuman.
- `supabase/README.md`: panduan setup backend dari awal sampai akhir.

Service Flutter untuk akses backend ada di:

```text
lib/backend/labin_repository.dart
```

Fitur backend yang sudah disiapkan:

- Auth + profile otomatis
- Lab, ruangan, fasilitas
- Kategori alat dan data alat
- Peminjaman alat + item + dokumen
- Reservasi ruangan
- Status tracking
- Laporan kerusakan + foto
- Pengumuman + lampiran
- Favorit
- Notifikasi
- Student staff shift, absensi, tugas, laporan harian
- Support message

## Verifikasi

```powershell
flutter analyze
flutter test
```
