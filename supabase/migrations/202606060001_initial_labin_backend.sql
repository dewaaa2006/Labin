-- Labin Supabase backend schema.
-- Run this in Supabase SQL editor or with `supabase db push`.

create extension if not exists "pgcrypto";

do $$
begin
  create type public.app_role as enum ('student', 'lecturer', 'technician', 'student_staff', 'admin');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.request_status as enum ('draft', 'pending', 'approved', 'rejected', 'picked_up', 'returned', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.reservation_status as enum ('pending', 'approved', 'rejected', 'ongoing', 'done', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.report_status as enum ('submitted', 'reviewing', 'in_progress', 'resolved', 'rejected');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.urgency_level as enum ('low', 'medium', 'high', 'critical');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.notification_type as enum ('loan', 'reservation', 'announcement', 'report', 'schedule', 'system');
exception when duplicate_object then null;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  nim text unique,
  email text not null,
  university text,
  faculty text,
  study_program text,
  avatar_url text,
  role public.app_role not null default 'student',
  rating numeric(3,2) not null default 5.00 check (rating >= 0 and rating <= 5),
  dark_mode boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.labs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  building text not null,
  floor text not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  lab_id uuid references public.labs(id) on delete set null,
  name text not null,
  capacity integer not null check (capacity > 0),
  photo_url text,
  availability_note text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.room_facilities (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  name text not null,
  is_available boolean not null default true,
  unique (room_id, name)
);

create table if not exists public.equipment_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon_name text,
  color_hex text not null default '#4F46E5',
  created_at timestamptz not null default now()
);

create table if not exists public.equipment (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.equipment_categories(id) on delete set null,
  lab_id uuid references public.labs(id) on delete set null,
  name text not null,
  slug text not null unique,
  specs text,
  description text,
  image_url text,
  total_stock integer not null default 1 check (total_stock >= 0),
  borrowed_stock integer not null default 0 check (borrowed_stock >= 0),
  condition_label text not null default 'Baik',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (borrowed_stock <= total_stock)
);

create table if not exists public.equipment_loans (
  id uuid primary key default gen_random_uuid(),
  borrower_id uuid not null references public.profiles(id) on delete cascade,
  purpose text not null,
  borrow_date date not null,
  return_date date not null,
  status public.request_status not null default 'pending',
  tracking_code text not null unique default ('LBN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(gen_random_uuid()::text, 1, 6))),
  admin_note text,
  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz,
  picked_up_at timestamptz,
  returned_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (return_date >= borrow_date)
);

create table if not exists public.equipment_loan_items (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.equipment_loans(id) on delete cascade,
  equipment_id uuid not null references public.equipment(id) on delete restrict,
  quantity integer not null default 1 check (quantity > 0),
  condition_before text,
  condition_after text,
  unique (loan_id, equipment_id)
);

create table if not exists public.loan_documents (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.equipment_loans(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  file_path text not null,
  file_name text not null,
  mime_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.room_reservations (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete restrict,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  activity_name text not null,
  activity_type text not null,
  participant_count integer not null check (participant_count > 0),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.reservation_status not null default 'pending',
  note text,
  admin_note text,
  approved_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table if not exists public.damage_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  room_id uuid references public.rooms(id) on delete set null,
  facility_name text not null,
  urgency public.urgency_level not null default 'medium',
  description text not null,
  status public.report_status not null default 'submitted',
  tracking_code text not null unique default ('RPT-' || upper(substr(gen_random_uuid()::text, 1, 6))),
  assigned_to uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.damage_report_photos (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.damage_reports(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  file_path text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references public.profiles(id) on delete set null,
  title text not null,
  category text not null default 'Pengumuman Umum',
  excerpt text,
  content text not null,
  is_pinned boolean not null default false,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.announcement_attachments (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  file_path text not null,
  file_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  equipment_id uuid references public.equipment(id) on delete cascade,
  room_id uuid references public.rooms(id) on delete cascade,
  created_at timestamptz not null default now(),
  check ((equipment_id is not null)::int + (room_id is not null)::int = 1),
  unique (user_id, equipment_id),
  unique (user_id, room_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type public.notification_type not null default 'system',
  title text not null,
  message text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.staff_shifts (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.profiles(id) on delete cascade,
  room_id uuid references public.rooms(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'scheduled',
  swap_requested boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table if not exists public.staff_attendance (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid references public.staff_shifts(id) on delete set null,
  staff_id uuid not null references public.profiles(id) on delete cascade,
  check_in_at timestamptz,
  check_out_at timestamptz,
  method text not null default 'qr',
  location_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_tasks (
  id uuid primary key default gen_random_uuid(),
  assignee_id uuid not null references public.profiles(id) on delete cascade,
  room_id uuid references public.rooms(id) on delete set null,
  title text not null,
  description text,
  priority text not null default 'medium',
  status text not null default 'todo',
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_daily_reports (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.profiles(id) on delete cascade,
  report_date date not null default current_date,
  summary text not null,
  issue_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (staff_id, report_date)
);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject text not null,
  message text not null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_equipment_category on public.equipment(category_id);
create index if not exists idx_equipment_slug on public.equipment(slug);
create index if not exists idx_equipment_loans_borrower on public.equipment_loans(borrower_id, status);
create index if not exists idx_room_reservations_room_time on public.room_reservations(room_id, starts_at, ends_at);
create index if not exists idx_damage_reports_status on public.damage_reports(status, urgency);
create index if not exists idx_notifications_user_read on public.notifications(user_id, read_at, created_at desc);
create index if not exists idx_announcements_published on public.announcements(is_pinned desc, published_at desc);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_labs_updated_at on public.labs;
create trigger set_labs_updated_at before update on public.labs
for each row execute function public.set_updated_at();

drop trigger if exists set_rooms_updated_at on public.rooms;
create trigger set_rooms_updated_at before update on public.rooms
for each row execute function public.set_updated_at();

drop trigger if exists set_equipment_updated_at on public.equipment;
create trigger set_equipment_updated_at before update on public.equipment
for each row execute function public.set_updated_at();

drop trigger if exists set_equipment_loans_updated_at on public.equipment_loans;
create trigger set_equipment_loans_updated_at before update on public.equipment_loans
for each row execute function public.set_updated_at();

drop trigger if exists set_room_reservations_updated_at on public.room_reservations;
create trigger set_room_reservations_updated_at before update on public.room_reservations
for each row execute function public.set_updated_at();

drop trigger if exists set_damage_reports_updated_at on public.damage_reports;
create trigger set_damage_reports_updated_at before update on public.damage_reports
for each row execute function public.set_updated_at();

drop trigger if exists set_announcements_updated_at on public.announcements;
create trigger set_announcements_updated_at before update on public.announcements
for each row execute function public.set_updated_at();

drop trigger if exists set_staff_shifts_updated_at on public.staff_shifts;
create trigger set_staff_shifts_updated_at before update on public.staff_shifts
for each row execute function public.set_updated_at();

drop trigger if exists set_staff_attendance_updated_at on public.staff_attendance;
create trigger set_staff_attendance_updated_at before update on public.staff_attendance
for each row execute function public.set_updated_at();

drop trigger if exists set_staff_tasks_updated_at on public.staff_tasks;
create trigger set_staff_tasks_updated_at before update on public.staff_tasks
for each row execute function public.set_updated_at();

drop trigger if exists set_staff_daily_reports_updated_at on public.staff_daily_reports;
create trigger set_staff_daily_reports_updated_at before update on public.staff_daily_reports
for each row execute function public.set_updated_at();

drop trigger if exists set_support_messages_updated_at on public.support_messages;
create trigger set_support_messages_updated_at before update on public.support_messages
for each row execute function public.set_updated_at();

create or replace function public.current_user_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_lab_operator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() in ('technician', 'student_staff', 'admin'), false)
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() = 'admin', false)
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    name,
    nim,
    email,
    university,
    faculty,
    study_program,
    role
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1), ''),
    nullif(new.raw_user_meta_data ->> 'nim', ''),
    new.email,
    new.raw_user_meta_data ->> 'university',
    new.raw_user_meta_data ->> 'faculty',
    new.raw_user_meta_data ->> 'study_program',
    case lower(coalesce(new.raw_user_meta_data ->> 'role', 'student'))
      when 'admin' then 'admin'::public.app_role
      when 'technician' then 'technician'::public.app_role
      when 'teknisi' then 'technician'::public.app_role
      when 'student_staff' then 'student_staff'::public.app_role
      when 'student staff' then 'student_staff'::public.app_role
      when 'lecturer' then 'lecturer'::public.app_role
      when 'dosen' then 'lecturer'::public.app_role
      else 'student'::public.app_role
    end
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.notify_loan_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.notifications(user_id, type, title, message, data)
    values (
      new.borrower_id,
      'loan',
      'Permohonan Peminjaman Dikirim',
      'Permohonan kamu sedang menunggu verifikasi admin.',
      jsonb_build_object('loan_id', new.id, 'tracking_code', new.tracking_code)
    );
  elsif new.status is distinct from old.status then
    insert into public.notifications(user_id, type, title, message, data)
    values (
      new.borrower_id,
      'loan',
      'Status Peminjaman: ' || initcap(new.status::text),
      'Status peminjaman ' || new.tracking_code || ' berubah.',
      jsonb_build_object('loan_id', new.id, 'tracking_code', new.tracking_code, 'status', new.status)
    );
  end if;
  return new;
end;
$$;

drop trigger if exists equipment_loan_notification on public.equipment_loans;
create trigger equipment_loan_notification
after insert or update of status on public.equipment_loans
for each row execute function public.notify_loan_status();

create or replace function public.notify_reservation_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.notifications(user_id, type, title, message, data)
    values (
      new.requester_id,
      'reservation',
      'Reservasi Dikirim',
      'Reservasi ruangan kamu sedang menunggu konfirmasi.',
      jsonb_build_object('reservation_id', new.id)
    );
  elsif new.status is distinct from old.status then
    insert into public.notifications(user_id, type, title, message, data)
    values (
      new.requester_id,
      'reservation',
      'Status Reservasi: ' || initcap(new.status::text),
      'Status reservasi ' || new.activity_name || ' berubah.',
      jsonb_build_object('reservation_id', new.id, 'status', new.status)
    );
  end if;
  return new;
end;
$$;

drop trigger if exists room_reservation_notification on public.room_reservations;
create trigger room_reservation_notification
after insert or update of status on public.room_reservations
for each row execute function public.notify_reservation_status();

alter table public.profiles enable row level security;
alter table public.labs enable row level security;
alter table public.rooms enable row level security;
alter table public.room_facilities enable row level security;
alter table public.equipment_categories enable row level security;
alter table public.equipment enable row level security;
alter table public.equipment_loans enable row level security;
alter table public.equipment_loan_items enable row level security;
alter table public.loan_documents enable row level security;
alter table public.room_reservations enable row level security;
alter table public.damage_reports enable row level security;
alter table public.damage_report_photos enable row level security;
alter table public.announcements enable row level security;
alter table public.announcement_attachments enable row level security;
alter table public.favorites enable row level security;
alter table public.notifications enable row level security;
alter table public.staff_shifts enable row level security;
alter table public.staff_attendance enable row level security;
alter table public.staff_tasks enable row level security;
alter table public.staff_daily_reports enable row level security;
alter table public.support_messages enable row level security;

drop policy if exists "profiles_select_own_or_operator" on public.profiles;
create policy "profiles_select_own_or_operator" on public.profiles
for select using (id = auth.uid() or public.is_lab_operator());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "profiles_admin_all" on public.profiles;
create policy "profiles_admin_all" on public.profiles
for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "labs_read_authenticated" on public.labs;
create policy "labs_read_authenticated" on public.labs
for select to authenticated using (is_active = true);

drop policy if exists "labs_operator_write" on public.labs;
create policy "labs_operator_write" on public.labs
for all using (public.is_lab_operator()) with check (public.is_lab_operator());

drop policy if exists "rooms_read_authenticated" on public.rooms;
create policy "rooms_read_authenticated" on public.rooms
for select to authenticated using (is_active = true);

drop policy if exists "rooms_operator_write" on public.rooms;
create policy "rooms_operator_write" on public.rooms
for all using (public.is_lab_operator()) with check (public.is_lab_operator());

drop policy if exists "room_facilities_read_authenticated" on public.room_facilities;
create policy "room_facilities_read_authenticated" on public.room_facilities
for select to authenticated using (true);

drop policy if exists "room_facilities_operator_write" on public.room_facilities;
create policy "room_facilities_operator_write" on public.room_facilities
for all using (public.is_lab_operator()) with check (public.is_lab_operator());

drop policy if exists "equipment_categories_read_authenticated" on public.equipment_categories;
create policy "equipment_categories_read_authenticated" on public.equipment_categories
for select to authenticated using (true);

drop policy if exists "equipment_categories_operator_write" on public.equipment_categories;
create policy "equipment_categories_operator_write" on public.equipment_categories
for all using (public.is_lab_operator()) with check (public.is_lab_operator());

drop policy if exists "equipment_read_authenticated" on public.equipment;
create policy "equipment_read_authenticated" on public.equipment
for select to authenticated using (is_active = true);

drop policy if exists "equipment_operator_write" on public.equipment;
create policy "equipment_operator_write" on public.equipment
for all using (public.is_lab_operator()) with check (public.is_lab_operator());

drop policy if exists "loans_owner_select" on public.equipment_loans;
create policy "loans_owner_select" on public.equipment_loans
for select using (borrower_id = auth.uid() or public.is_lab_operator());

drop policy if exists "loans_owner_insert" on public.equipment_loans;
create policy "loans_owner_insert" on public.equipment_loans
for insert with check (borrower_id = auth.uid());

drop policy if exists "loans_owner_cancel" on public.equipment_loans;
create policy "loans_owner_cancel" on public.equipment_loans
for update using (borrower_id = auth.uid() or public.is_lab_operator())
with check (borrower_id = auth.uid() or public.is_lab_operator());

drop policy if exists "loan_items_related_access" on public.equipment_loan_items;
create policy "loan_items_related_access" on public.equipment_loan_items
for all using (
  exists (
    select 1 from public.equipment_loans l
    where l.id = loan_id and (l.borrower_id = auth.uid() or public.is_lab_operator())
  )
) with check (
  exists (
    select 1 from public.equipment_loans l
    where l.id = loan_id and (l.borrower_id = auth.uid() or public.is_lab_operator())
  )
);

drop policy if exists "loan_documents_related_access" on public.loan_documents;
create policy "loan_documents_related_access" on public.loan_documents
for all using (owner_id = auth.uid() or public.is_lab_operator())
with check (owner_id = auth.uid() or public.is_lab_operator());

drop policy if exists "reservations_owner_select" on public.room_reservations;
create policy "reservations_owner_select" on public.room_reservations
for select using (requester_id = auth.uid() or public.is_lab_operator());

drop policy if exists "reservations_owner_insert" on public.room_reservations;
create policy "reservations_owner_insert" on public.room_reservations
for insert with check (requester_id = auth.uid());

drop policy if exists "reservations_owner_or_operator_update" on public.room_reservations;
create policy "reservations_owner_or_operator_update" on public.room_reservations
for update using (requester_id = auth.uid() or public.is_lab_operator())
with check (requester_id = auth.uid() or public.is_lab_operator());

drop policy if exists "reports_owner_select" on public.damage_reports;
create policy "reports_owner_select" on public.damage_reports
for select using (reporter_id = auth.uid() or public.is_lab_operator());

drop policy if exists "reports_owner_insert" on public.damage_reports;
create policy "reports_owner_insert" on public.damage_reports
for insert with check (reporter_id = auth.uid());

drop policy if exists "reports_owner_or_operator_update" on public.damage_reports;
create policy "reports_owner_or_operator_update" on public.damage_reports
for update using (reporter_id = auth.uid() or public.is_lab_operator())
with check (reporter_id = auth.uid() or public.is_lab_operator());

drop policy if exists "report_photos_related_access" on public.damage_report_photos;
create policy "report_photos_related_access" on public.damage_report_photos
for all using (owner_id = auth.uid() or public.is_lab_operator())
with check (owner_id = auth.uid() or public.is_lab_operator());

drop policy if exists "announcements_read_authenticated" on public.announcements;
create policy "announcements_read_authenticated" on public.announcements
for select to authenticated using (published_at <= now());

drop policy if exists "announcements_operator_write" on public.announcements;
create policy "announcements_operator_write" on public.announcements
for all using (public.is_lab_operator()) with check (public.is_lab_operator());

drop policy if exists "announcement_attachments_read_authenticated" on public.announcement_attachments;
create policy "announcement_attachments_read_authenticated" on public.announcement_attachments
for select to authenticated using (true);

drop policy if exists "announcement_attachments_operator_write" on public.announcement_attachments;
create policy "announcement_attachments_operator_write" on public.announcement_attachments
for all using (public.is_lab_operator()) with check (public.is_lab_operator());

drop policy if exists "favorites_owner_all" on public.favorites;
create policy "favorites_owner_all" on public.favorites
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "notifications_owner_all" on public.notifications;
create policy "notifications_owner_all" on public.notifications
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "staff_shifts_staff_or_operator" on public.staff_shifts;
create policy "staff_shifts_staff_or_operator" on public.staff_shifts
for all using (staff_id = auth.uid() or public.is_lab_operator())
with check (staff_id = auth.uid() or public.is_lab_operator());

drop policy if exists "staff_attendance_staff_or_operator" on public.staff_attendance;
create policy "staff_attendance_staff_or_operator" on public.staff_attendance
for all using (staff_id = auth.uid() or public.is_lab_operator())
with check (staff_id = auth.uid() or public.is_lab_operator());

drop policy if exists "staff_tasks_staff_or_operator" on public.staff_tasks;
create policy "staff_tasks_staff_or_operator" on public.staff_tasks
for all using (assignee_id = auth.uid() or public.is_lab_operator())
with check (assignee_id = auth.uid() or public.is_lab_operator());

drop policy if exists "staff_daily_reports_staff_or_operator" on public.staff_daily_reports;
create policy "staff_daily_reports_staff_or_operator" on public.staff_daily_reports
for all using (staff_id = auth.uid() or public.is_lab_operator())
with check (staff_id = auth.uid() or public.is_lab_operator());

drop policy if exists "support_messages_owner_or_operator" on public.support_messages;
create policy "support_messages_owner_or_operator" on public.support_messages
for all using (user_id = auth.uid() or public.is_lab_operator())
with check (user_id = auth.uid() or public.is_lab_operator());

insert into storage.buckets (id, name, public)
values
  ('loan-documents', 'loan-documents', false),
  ('damage-report-photos', 'damage-report-photos', false),
  ('announcement-attachments', 'announcement-attachments', false),
  ('public-assets', 'public-assets', true)
on conflict (id) do nothing;

drop policy if exists "loan_documents_storage_owner" on storage.objects;
create policy "loan_documents_storage_owner" on storage.objects
for all using (
  bucket_id = 'loan-documents'
  and (auth.uid()::text = (storage.foldername(name))[1] or public.is_lab_operator())
) with check (
  bucket_id = 'loan-documents'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "damage_photos_storage_owner" on storage.objects;
create policy "damage_photos_storage_owner" on storage.objects
for all using (
  bucket_id = 'damage-report-photos'
  and (auth.uid()::text = (storage.foldername(name))[1] or public.is_lab_operator())
) with check (
  bucket_id = 'damage-report-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "announcement_attachments_storage_read" on storage.objects;
create policy "announcement_attachments_storage_read" on storage.objects
for select using (bucket_id = 'announcement-attachments' and auth.role() = 'authenticated');

drop policy if exists "announcement_attachments_storage_operator" on storage.objects;
create policy "announcement_attachments_storage_operator" on storage.objects
for all using (bucket_id = 'announcement-attachments' and public.is_lab_operator())
with check (bucket_id = 'announcement-attachments' and public.is_lab_operator());

drop policy if exists "public_assets_read" on storage.objects;
create policy "public_assets_read" on storage.objects
for select using (bucket_id = 'public-assets');

drop policy if exists "public_assets_operator_write" on storage.objects;
create policy "public_assets_operator_write" on storage.objects
for all using (bucket_id = 'public-assets' and public.is_lab_operator())
with check (bucket_id = 'public-assets' and public.is_lab_operator());
