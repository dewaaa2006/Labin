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

### 3. Database Lokal, Paling Gampang

Backend dev sekarang memakai SQLite lokal supaya langsung jalan tanpa XAMPP, PostgreSQL, atau Docker.

```powershell
npm run db:sqlite
```

Command itu membuat `backend/prisma/dev.db` dan mengisi seed data.

### 4. Database PostgreSQL Opsional

Kalau nanti mau kembali ke PostgreSQL production, ubah `backend/prisma/schema.prisma` provider ke `postgresql`, isi `DATABASE_URL`, lalu jalankan migrate Prisma.

Kalau pakai Docker:

```powershell
docker compose up -d
npm run db:migrate
npm run seed
```

Catatan mesin ini saat dikonfigurasi belum punya PostgreSQL lokal, `psql`, atau Docker, jadi migrasi belum dieksekusi di database lokal. File `.env`, Prisma Client, dan migration SQL sudah siap.

Seed login:

```text
admin@labin.id / Admin123!
staff1@labin.id / Staff123!
mahasiswa1@labin.id / Mhs123!
```

### 5. Run

```powershell
npm run dev
```

Backend: `http://localhost:3001`

Frontend: `http://localhost:5173`

### 6. Build

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
