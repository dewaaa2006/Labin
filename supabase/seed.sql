-- Labin seed data for local development and first Supabase setup.

insert into public.equipment_categories (name, icon_name, color_hex)
values
  ('Komputer', 'laptop_mac_rounded', '#1E1B4B'),
  ('Studio', 'photo_camera_rounded', '#7C3AED'),
  ('Jaringan', 'router_rounded', '#06B6D4'),
  ('Multimedia', 'movie_creation_rounded', '#4F46E5'),
  ('Elektronika', 'memory_rounded', '#10B981'),
  ('Alat Ukur', 'monitor_heart_rounded', '#F59E0B')
on conflict (name) do update set
  icon_name = excluded.icon_name,
  color_hex = excluded.color_hex;

with upsert_labs as (
  insert into public.labs (name, building, floor, description)
  values
    ('Lab Komputer', 'Gedung B', 'Lantai 2', 'Ruang praktikum pemrograman, basis data, dan mobile.'),
    ('Lab Studio', 'Gedung C', 'Lantai 1', 'Ruang produksi konten, fotografi, dan multimedia.'),
    ('Lab Jaringan', 'Gedung B', 'Lantai 3', 'Ruang praktikum jaringan komputer dan infrastruktur.')
  on conflict do nothing
  returning id, name
)
insert into public.rooms (lab_id, name, capacity, availability_note)
select labs.id, seed.name, seed.capacity, seed.availability_note
from (
  values
    ('Lab Komputer', 'Lab Komputer A', 40, 'Tersedia 13:00-15:00'),
    ('Lab Komputer', 'Lab Komputer B', 36, 'Tersedia 09:00-11:00'),
    ('Lab Studio', 'Lab Studio', 24, 'Tersedia 15:00-17:00'),
    ('Lab Jaringan', 'Lab Jaringan', 32, 'Tersedia 09:00-11:00')
) as seed(lab_name, name, capacity, availability_note)
join public.labs labs on labs.name = seed.lab_name
where not exists (
  select 1 from public.rooms rooms where rooms.name = seed.name
);

insert into public.room_facilities (room_id, name, is_available)
select rooms.id, facility.name, true
from public.rooms rooms
cross join (
  values ('AC'), ('Proyektor'), ('Internet'), ('Whiteboard')
) as facility(name)
on conflict (room_id, name) do nothing;

insert into public.equipment (
  category_id,
  lab_id,
  name,
  slug,
  specs,
  description,
  total_stock,
  borrowed_stock,
  condition_label
)
select category.id, lab.id, seed.name, seed.slug, seed.specs, seed.description, seed.total_stock, seed.borrowed_stock, seed.condition_label
from (
  values
    ('Studio', 'Lab Studio', 'Kamera DSLR Canon EOS 90D', 'kamera-dslr-canon-eos-90d', '32MP, 4K video', 'Kamera untuk praktikum fotografi, dokumentasi, dan produksi konten lab.', 3, 1, 'Baik'),
    ('Jaringan', 'Lab Jaringan', 'Router MikroTik RB951', 'router-mikrotik-rb951', '5 port ethernet', 'Router praktikum konfigurasi jaringan dasar sampai menengah.', 8, 0, 'Baik'),
    ('Alat Ukur', 'Lab Jaringan', 'Oscilloscope Digital', 'oscilloscope-digital', '100MHz, dual channel', 'Alat ukur sinyal untuk praktikum elektronika dan jaringan.', 2, 2, 'Perlu Dicek'),
    ('Komputer', 'Lab Komputer', 'Laptop Praktikum Dell', 'laptop-praktikum-dell', 'Core i7, 16GB RAM', 'Laptop cadangan untuk praktikum mobile dan basis data.', 12, 3, 'Baik')
) as seed(category_name, lab_name, name, slug, specs, description, total_stock, borrowed_stock, condition_label)
join public.equipment_categories category on category.name = seed.category_name
join public.labs lab on lab.name = seed.lab_name
on conflict (slug) do update set
  specs = excluded.specs,
  description = excluded.description,
  total_stock = excluded.total_stock,
  borrowed_stock = excluded.borrowed_stock,
  condition_label = excluded.condition_label,
  updated_at = now();

insert into public.announcements (title, category, excerpt, content, is_pinned, published_at)
values
  (
    'Maintenance Lab Studio 7-9 Juni',
    'Maintenance',
    'Lab Studio ditutup sementara untuk perawatan perangkat audio visual.',
    'Lab Studio ditutup sementara pada 7-9 Juni 2026 untuk perawatan kamera, audio interface, lighting, dan komputer editing. Reservasi yang terdampak akan dijadwalkan ulang oleh admin.',
    true,
    now() - interval '2 hours'
  ),
  (
    'Rekrutmen Student Staff Dibuka',
    'Rekrutmen',
    'Daftar sebelum 15 Juni 2026 dan bantu operasional lab kampus.',
    'Pendaftaran Student Staff periode Juni 2026 dibuka. Kandidat terpilih akan membantu absensi, inventaris, peminjaman alat, dan pendampingan praktikum.',
    false,
    now() - interval '1 day'
  ),
  (
    'SOP Peminjaman Alat Diperbarui',
    'Pengumuman Umum',
    'Mahasiswa wajib mengunggah KTM dan surat izin untuk alat bernilai tinggi.',
    'Mulai Juni 2026, peminjaman alat bernilai tinggi wajib menyertakan KTM aktif dan surat izin dari dosen pengampu atau koordinator lab.',
    false,
    now() - interval '3 days'
  )
on conflict do nothing;
