# Labin Supabase Backend

Folder ini berisi backend Supabase untuk semua fitur utama Labin.

## 1. Buat Project Supabase

1. Buka Supabase Dashboard.
2. Buat project baru, misalnya `Labin`.
3. Simpan `Project URL` dan `publishable key`.
4. Jangan masukkan `service_role key` ke Flutter.

## 2. Jalankan Schema

Cara paling gampang:

1. Buka Supabase Dashboard.
2. Masuk ke SQL Editor.
3. Copy isi file `migrations/202606060001_initial_labin_backend.sql`.
4. Run.
5. Copy isi file `seed.sql`.
6. Run.

Jika memakai Supabase CLI:

```powershell
supabase link --project-ref your-project-ref
supabase db push
supabase db reset
```

`db reset` hanya untuk local/dev karena akan reset database.

## 3. Jalankan Flutter Dengan Supabase

```powershell
flutter run `
  --dart-define=LABIN_SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=LABIN_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Build APK:

```powershell
flutter build apk --debug `
  --dart-define=LABIN_SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=LABIN_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

## 4. Auth

Email/password sudah siap melalui Supabase Auth.

Register Flutter mengirim metadata:

- `name`
- `nim`
- `university`
- `faculty`
- `study_program`
- `role`

Trigger `handle_new_user()` otomatis membuat row di tabel `profiles`.

Perilaku app:

- Login hanya berhasil jika email/password valid di Supabase Auth.
- Register benar-benar membuat user baru di Supabase Auth.
- Jika email confirmation Supabase aktif, user diminta cek email lalu login setelah verifikasi.
- Jika email confirmation tidak aktif, Supabase membuat session dan app langsung masuk dashboard.
- Jika `LABIN_SUPABASE_URL` atau `LABIN_SUPABASE_PUBLISHABLE_KEY` belum diisi, login/register ditolak dan tidak masuk dashboard.

Untuk development yang cepat, bisa matikan sementara email confirmation:

Auth -> Providers -> Email -> Confirm email = off.

Untuk production, aktifkan email confirmation.

## 5. Google OAuth

Di Supabase Dashboard:

1. Auth -> Providers -> Google.
2. Enable Google.
3. Isi Client ID dan Client Secret dari Google Cloud.
4. Tambahkan redirect URL:

```text
io.supabase.labin://login-callback/
```

Android manifest sudah ditambahkan intent-filter untuk callback ini.

## 6. Storage Buckets

Migration membuat bucket:

- `loan-documents`: dokumen KTM/surat izin peminjaman.
- `damage-report-photos`: foto laporan kerusakan.
- `announcement-attachments`: lampiran pengumuman.
- `public-assets`: asset publik seperti foto alat/ruangan.

Policy storage:

- User hanya bisa membaca/menulis file miliknya sendiri untuk dokumen dan foto laporan.
- Operator lab bisa membaca file operasional.
- Announcement attachment bisa dibaca user login.
- Public assets bisa dibaca publik.

## 7. Role

Enum `app_role`:

- `student`
- `lecturer`
- `technician`
- `student_staff`
- `admin`

Helper SQL:

- `current_user_role()`
- `is_lab_operator()`
- `is_admin()`

Operator lab adalah:

- `technician`
- `student_staff`
- `admin`

## 8. Mapping Fitur Ke Tabel

Home:

- `equipment_loans`
- `room_reservations`
- `announcements`
- `notifications`

Lab:

- `equipment_categories`
- `equipment`
- `labs`

Detail alat:

- `equipment`
- `favorites`
- `equipment_loans`

Peminjaman alat:

- `equipment_loans`
- `equipment_loan_items`
- `loan_documents`
- `notifications`

Jadwal dan reservasi:

- `rooms`
- `room_facilities`
- `room_reservations`
- `notifications`

Status tracking:

- `equipment_loans`
- `equipment_loan_items`
- `room_reservations`
- `damage_reports`

Laporan kerusakan:

- `damage_reports`
- `damage_report_photos`
- `notifications`

Pengumuman:

- `announcements`
- `announcement_attachments`

Profil:

- `profiles`
- `favorites`
- `equipment_loans`
- `room_reservations`
- `damage_reports`

Notifikasi:

- `notifications`

Student Staff Portal:

- `staff_shifts`
- `staff_attendance`
- `staff_tasks`
- `staff_daily_reports`

Support:

- `support_messages`

## 9. RLS Ringkas

Semua tabel utama memakai Row Level Security.

- User bisa melihat dan mengubah data miliknya sendiri.
- Operator lab bisa melihat dan memproses data operasional.
- Admin punya akses penuh.
- Data master lab, ruangan, kategori, alat, dan pengumuman bisa dibaca user login.
- Data master hanya bisa ditulis operator/admin.

## 10. File Flutter Backend

Service Flutter ada di:

```text
lib/backend/labin_repository.dart
```

Class utama:

```dart
LabinRepository(client: LabinBackend.client)
```

Method yang tersedia:

- `fetchEquipment()`
- `fetchRooms()`
- `fetchAnnouncements()`
- `fetchNotifications()`
- `markNotificationRead()`
- `createEquipmentLoan()`
- `fetchMyLoans()`
- `createRoomReservation()`
- `fetchMyReservations()`
- `createDamageReport()`
- `fetchMyDamageReports()`
- `toggleEquipmentFavorite()`
- `fetchStaffDashboard()`
