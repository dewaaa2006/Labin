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

## Verifikasi

```powershell
flutter analyze
flutter test
```
