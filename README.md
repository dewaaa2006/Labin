# Labin

Prototype mobile app Flutter untuk smart laboratory management.

## Run mode demo

```powershell
flutter run
```

Jika Supabase belum dikonfigurasi, login/register akan masuk ke dashboard demo.

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
