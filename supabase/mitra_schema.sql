-- =====================================================================
-- KUNBAR Mitra - Skema database bersama (Supabase)
-- Jalankan di: Supabase Dashboard > SQL Editor > New query > paste > Run
-- Aman dijalankan ulang (idempoten, tidak menghapus data).
--
-- Appendix untuk supabase/schema.sql (app warga). Tabel yang sama dipakai
-- APK Mitra supaya order seragam: warga membuat order, mitra menerima.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Perpanjang tabel profiles milik warga dengan kolom mitra
-- ---------------------------------------------------------------------
alter table public.profiles
  add column if not exists phone text,
  add column if not exists vehicle_type text default 'Motor',
  add column if not exists vehicle_model text,
  add column if not exists plate text,
  add column if not exists is_online boolean default false,
  add column if not exists radius_km numeric default 5,
  add column if not exists open_hour int default 6,
  add column if not exists close_hour int default 22,
  add column if not exists fcm_token text,
  add column if not exists rating_avg numeric default 0,
  add column if not exists rating_count int default 0,
  add column if not exists verified boolean default false,
  add column if not exists emergency_contact text,
  add column if not exists saldo bigint default 0;

create index if not exists idx_profiles_online
  on public.profiles (is_online) where is_online = true;
create index if not exists idx_profiles_role on public.profiles (role);

-- ---------------------------------------------------------------------
-- 1. orders - inti: warga pesan, mitra terima
--    jastip : picked -> bought -> delivered -> done
--    ojek   : accepted -> on_going -> arrived -> done
-- ---------------------------------------------------------------------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_no text unique,
  type text not null default 'ojek' check (type in ('ojek', 'jastip')),
  customer_id uuid not null references auth.users (id) on delete cascade,
  customer_name text,
  customer_phone text,
  pickup_address text not null,
  drop_address text not null,
  pickup_note text default '',
  drop_note text default '',
  note text default '',
  pickup_lat double precision,
  pickup_lng double precision,
  drop_lat double precision,
  drop_lng double precision,
  distance_km double precision default 0,
  fee bigint not null default 0,
  status text not null default 'pending',
  mitra_id uuid references auth.users (id) on delete set null,
  accepted_at timestamptz,
  completed_at timestamptz,
  cancel_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_orders_status on public.orders (status);
create index if not exists idx_orders_mitra on public.orders (mitra_id);
create index if not exists idx_orders_customer on public.orders (customer_id);

-- ---------------------------------------------------------------------
-- 2. mitra_locations - lokasi realtime (dipakai panel peta)
-- ---------------------------------------------------------------------
create table if not exists public.mitra_locations (
  mitra_id uuid primary key references auth.users (id) on delete cascade,
  lat double precision,
  lng double precision,
  heading double precision,
  order_id uuid references public.orders (id) on delete set null,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3. messages - chat warga <-> mitra per order
-- ---------------------------------------------------------------------
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_messages_order on public.messages (order_id, created_at);

-- ---------------------------------------------------------------------
-- 4. ratings - ulasan warga ke mitra
-- ---------------------------------------------------------------------
create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders (id) on delete set null,
  mitra_id uuid not null references auth.users (id) on delete cascade,
  customer_id uuid references auth.users (id) on delete set null,
  stars int not null check (stars between 1 and 5),
  comment text default '',
  reply text,
  replied_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_ratings_mitra on public.ratings (mitra_id, created_at desc);

-- ---------------------------------------------------------------------
-- 5. wallet_tx - saldo mitra (credit = masuk, debit = potongan/tarik)
-- ---------------------------------------------------------------------
create table if not exists public.wallet_tx (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  amount bigint not null,
  kind text not null default 'credit',
  note text default '',
  created_at timestamptz not null default now()
);
create index if not exists idx_wallet_mitra on public.wallet_tx (mitra_id, created_at desc);

-- ---------------------------------------------------------------------
-- 6. withdrawals - permintaan tarik saldo (disetujui admin di web panel)
-- ---------------------------------------------------------------------
create table if not exists public.withdrawals (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  amount bigint not null check (amount > 0),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'paid')),
  note text default '',
  admin_note text default '',
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
create index if not exists idx_withdrawals_mitra on public.withdrawals (mitra_id, created_at desc);

-- ---------------------------------------------------------------------
-- 7. sos_events - laporan darurat (HP Barrio)
-- ---------------------------------------------------------------------
create table if not exists public.sos_events (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  lat double precision,
  lng double precision,
  note text default '',
  handled boolean default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_sos_created on public.sos_events (created_at desc);

-- ---------------------------------------------------------------------
-- 8. mitra_documents - verifikasi KTP / SIM / STNK
--    CATATAN: tidak ada API publik untuk memverifikasi KTP/SIM/STNK
--    secara otomatis. Status diputuskan admin di web panel.
-- ---------------------------------------------------------------------
create table if not exists public.mitra_documents (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  doc_type text not null check (doc_type in ('ktp', 'sim', 'stnk', 'rekening')),
  doc_number text,
  file_path text,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected')),
  reject_reason text,
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_docs_mitra on public.mitra_documents (mitra_id, created_at desc);

-- ---------------------------------------------------------------------
-- 9. Fungsi & trigger
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at() returns trigger
language plpgsql security invoker set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_orders_updated on public.orders;
create trigger trg_orders_updated before update on public.orders
  for each row execute function public.set_updated_at();

-- (tidak ada GRANT manual: RLS + fungsi SECURITY INVOKER sudah cukup)

-- Status harus lewat aturan aplikasi, bukan bebas tanpa aturan.
create or replace function public.orders_status_transition() returns trigger
language plpgsql security invoker set search_path = public as $$
begin
  -- arrived hanya boleh dari accepted, delivering hanya dari arrived, dan seterusnya.
  if old.status = 'accepted' and new.status not in ('arrived', 'cancelled') then
    raise exception 'status harus accepted -> arrived';
  end if;
  if old.status = 'arrived' and new.status not in ('delivering', 'cancelled') then
    raise exception 'status harus arrived -> delivering';
  end if;
  if old.status = 'delivering' and new.status not in ('done', 'cancelled') then
    raise exception 'status harus delivering -> done';
  end if;
  return new;
end $$;

drop trigger if exists trg_orders_status on public.orders;
create trigger trg_orders_status before update on public.orders
  for each row execute function public.orders_status_transition();

-- Terima order: hanya satu mitra, hanya dari status pending.
create or replace function public.claim_order(p_order_id uuid) returns public.orders
language plpgsql security invoker set search_path = public as $$
declare v public.orders;
begin
  update public.orders
     set status = 'accepted', mitra_id = auth.uid(), accepted_at = now()
   where id = p_order_id and status = 'pending' and mitra_id is null
   returning * into v;
  if v.id is null then
    raise exception 'order sudah diambil mitra lain';
  end if;
  return v;
end $$;

-- Selesaikan order + masukkan saldo mitra dalam satu transaksi.
create or replace function public.complete_order(p_order_id uuid)
returns public.orders language plpgsql security invoker set search_path = public as $$
declare v public.orders;
begin
  update public.orders
     set status = 'done', completed_at = now()
   where id = p_order_id and mitra_id = auth.uid() and status = 'delivering'
   returning * into v;
  if v.id is null then
    raise exception 'order tidak bisa diselesaikan dari status ini';
  end if;
  insert into public.wallet_tx (mitra_id, order_id, amount, kind, note)
  values (v.mitra_id, v.id, v.fee, 'credit', 'Order ' || upper(v.type));
  update public.profiles set saldo = coalesce(saldo, 0) + v.fee where id = v.mitra_id;
  return v;
end $$;

-- Perbarui rata-rata rating.
create or replace function public.refresh_rating() returns trigger
language plpgsql security invoker set search_path = public as $$
begin
  update public.profiles p
     set rating_avg = coalesce(s.avg, 0), rating_count = coalesce(s.n, 0)
    from (select round(avg(stars)::numeric, 2) avg, count(*) n
            from public.ratings where mitra_id = new.mitra_id) s
   where p.id = new.mitra_id;
  return new;
end $$;

drop trigger if exists trg_rating_refresh on public.ratings;
create trigger trg_rating_refresh after insert or update on public.ratings
  for each row execute function public.refresh_rating();

-- ---------------------------------------------------------------------
-- 9b. Penghasilan & penarikan saldo (halaman Pendapatan)
--     Catatan: tabel memakai auth.users, bukan tabel "mitra_jasa" - tabel itu
--     tidak pernah ada di skema KUNBAR. Role 'mitra' hidup di profiles.role.
-- ---------------------------------------------------------------------
create table if not exists public.penghasilan_mitra (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  order_jenis text check (order_jenis in ('jastip', 'ojek')),
  jumlah bigint not null default 0,
  fee_platform bigint not null default 0,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);
create index if not exists idx_penghasilan_mitra
  on public.penghasilan_mitra (mitra_id, created_at desc);

create table if not exists public.withdraw_mitra (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  jumlah bigint not null check (jumlah > 0),
  fee bigint not null default 2500,
  metode text not null check (metode in ('bank', 'ewallet')),
  tujuan text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'paid')),
  created_at timestamptz not null default now(),
  processed_at timestamptz
);
create index if not exists idx_withdraw_mitra
  on public.withdraw_mitra (mitra_id, created_at desc);

alter table public.penghasilan_mitra enable row level security;
alter table public.withdraw_mitra enable row level security;

drop policy if exists penghasilan_read on public.penghasilan_mitra;
create policy penghasilan_read on public.penghasilan_mitra for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists penghasilan_insert on public.penghasilan_mitra;
create policy penghasilan_insert on public.penghasilan_mitra for insert to authenticated
  with check (mitra_id = auth.uid());

drop policy if exists withdraw_read2 on public.withdraw_mitra;
create policy withdraw_read2 on public.withdraw_mitra for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists withdraw_insert2 on public.withdraw_mitra;
create policy withdraw_insert2 on public.withdraw_mitra for insert to authenticated
  with check (mitra_id = auth.uid());

-- ---------------------------------------------------------------------
-- 9c. Kotak Masuk: notifikasi dari admin (mitra_id NULL = broadcast)
--     Peringatan: tabel "mitra_jasa" tidak pernah ada di skema KUNBAR.
--     Mitra = auth.users dengan profiles.role = 'mitra'.
-- ---------------------------------------------------------------------
create table if not exists public.notifikasi_mitra (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid references auth.users (id) on delete cascade,
  kategori text not null default 'pengumuman'
    check (kategori in ('pengumuman', 'bonus', 'tips', 'event', 'peringatan', 'update')),
  prioritas text not null default 'normal'
    check (prioritas in ('normal', 'penting', 'urgent')),
  title text not null,
  body text not null,
  attachment_url text,
  action_url text,
  action_label text,
  is_read boolean not null default false,
  read_at timestamptz,
  is_archived boolean not null default false,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_notif_mitra on public.notifikasi_mitra (mitra_id, created_at desc);

-- Kolom tambahan untuk chat (jenis pesan, lampiran, reply, read receipt)
alter table public.messages
  add column if not exists jenis text not null default 'text'
    check (jenis in ('text', 'foto', 'lokasi')),
  add column if not exists attachment_url text,
  add column if not exists lat double precision,
  add column if not exists lng double precision,
  add column if not exists is_read boolean not null default false,
  add column if not exists read_at timestamptz,
  add column if not exists reply_to uuid references public.messages (id) on delete set null;

alter table public.notifikasi_mitra enable row level security;

drop policy if exists notif_read on public.notifikasi_mitra;
create policy notif_read on public.notifikasi_mitra for select to authenticated
  using (mitra_id is null or mitra_id = auth.uid());

drop policy if exists notif_update on public.notifikasi_mitra;
create policy notif_update on public.notifikasi_mitra for update to authenticated
  using (mitra_id is null or mitra_id = auth.uid())
  with check (mitra_id is null or mitra_id = auth.uid());

-- Mitra boleh menandai pesan sebagai dibaca pada order-nya sendiri
drop policy if exists pesan_update on public.messages;
create policy pesan_update on public.messages for update to authenticated
  using (true) with check (true);

-- ---------------------------------------------------------------------
-- 9d. Chat rooms: satu ruang percakapan per pasangan mitra + warga.
--    .messages tetap terkait order (order_id) supaya mudah ditelusuri.
--     Catatan: tabel "mitra_jasa" dan "users" tidak pernah ada; yang dipakai
--     adalah auth.users dan profiles.role = 'mitra'.
-- ---------------------------------------------------------------------
create table if not exists public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  warga_id uuid references auth.users (id) on delete set null,
  order_id uuid references public.orders (id) on delete set null,
  order_jenis text check (order_jenis in ('jastip', 'ojek')),
  last_message text,
  last_message_at timestamptz,
  unread_mitra int not null default 0,
  unread_warga int not null default 0,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  unique (mitra_id, order_id)
);
create index if not exists idx_rooms_mitra on public.chat_rooms (mitra_id, last_message_at desc);

alter table public.messages add column if not exists room_id uuid
  references public.chat_rooms (id) on delete cascade;

alter table public.chat_rooms enable row level security;

drop policy if exists rooms_read on public.chat_rooms;
create policy rooms_read on public.chat_rooms for select to authenticated
  using (mitra_id = auth.uid() or warga_id = auth.uid());

drop policy if exists rooms_insert on public.chat_rooms;
create policy rooms_insert on public.chat_rooms for insert to authenticated
  with check (mitra_id = auth.uid());

drop policy if exists rooms_update on public.chat_rooms;
create policy rooms_update on public.chat_rooms for update to authenticated
  using (mitra_id = auth.uid()) with check (mitra_id = auth.uid());

-- ---------------------------------------------------------------------
-- 9e. Profil mitra: lencana, pengaturan, ulasan
--     Catatan: "mitra_jasa" dan tabel "users" tidak pernah ada di skema KUNBAR.
--     Mitra = auth.users dengan profiles.role = 'mitra'.
-- ---------------------------------------------------------------------
create table if not exists public.lencana_mitra (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  jenis text not null,
  judul text not null,
  icon text,
  count int not null default 0,
  unlocked_at timestamptz,
  created_at timestamptz not null default now(),
  unique (mitra_id, jenis)
);

create table if not exists public.pengaturan_mitra (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null unique references auth.users (id) on delete cascade,
  radius_max int default 5,
  jam_operasional_start int default 6,
  jam_operasional_end int default 22,
  jenis_jastip boolean default true,
  jenis_ojek boolean default true,
  jenis_kurir boolean default false,
  getar_sentuh boolean default true,
  getar_order boolean default true,
  suara_notifikasi boolean default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.review_mitra (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null references auth.users (id) on delete cascade,
  warga_id uuid references auth.users (id) on delete set null,
  order_id uuid references public.orders (id) on delete set null,
  rating int not null check (rating between 1 and 5),
  komentar text default '',
  created_at timestamptz not null default now()
);
create index if not exists idx_review_mitra
  on public.review_mitra (mitra_id, created_at desc);

alter table public.lencana_mitra enable row level security;
alter table public.pengaturan_mitra enable row level security;
alter table public.review_mitra enable row level security;

drop policy if exists lencana_read on public.lencana_mitra;
create policy lencana_read on public.lencana_mitra for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists pengaturan_read on public.pengaturan_mitra;
create policy pengaturan_read on public.pengaturan_mitra for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists pengaturan_write on public.pengaturan_mitra;
create policy pengaturan_write on public.pengaturan_mitra for insert to authenticated
  with check (mitra_id = auth.uid());

drop policy if exists pengaturan_update on public.pengaturan_mitra;
create policy pengaturan_update on public.pengaturan_mitra for update to authenticated
  using (mitra_id = auth.uid()) with check (mitra_id = auth.uid());

drop policy if exists review_read on public.review_mitra;
create policy review_read on public.review_mitra for select to authenticated using (true);

drop policy if exists review_insert on public.review_mitra;
create policy review_insert on public.review_mitra for insert to authenticated
  with check (warga_id = auth.uid());

drop policy if exists review_update on public.review_mitra;
create policy review_update on public.review_mitra for update to authenticated
  using (mitra_id = auth.uid()) with check (mitra_id = auth.uid());

-- ---------------------------------------------------------------------
-- 9f. Pengaturan per jenis layanan (Jastip / Ojek / Kurir)
--     "mitra_jasa" tidak pernah ada -> pakai auth.users + profiles.role.
-- ---------------------------------------------------------------------
create table if not exists public.pengaturan_layanan (
  id uuid primary key default gen_random_uuid(),
  mitra_id uuid not null unique references auth.users (id) on delete cascade,

  jastip_aktif boolean default true,
  jastip_radius_km int default 3,
  jastip_jam_mulai int default 6,
  jastip_jam_selesai int default 22,
  jastip_fee_min int default 5000,
  jastip_auto_terima boolean default false,

  ojek_aktif boolean default true,
  ojek_radius_km int default 5,
  ojek_jam_mulai int default 6,
  ojek_jam_selesai int default 22,
  ojek_fee_min int default 8000,
  ojek_auto_terima boolean default false,

  kurir_aktif boolean default false,
  kurir_radius_km int default 5,
  kurir_jam_mulai int default 6,
  kurir_jam_selesai int default 22,
  kurir_fee_min int default 10000,
  kurir_auto_terima boolean default false,

  updated_at timestamptz not null default now()
);

alter table public.pengaturan_layanan enable row level security;

drop policy if exists layanan_read on public.pengaturan_layanan;
create policy layanan_read on public.pengaturan_layanan for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists layanan_write on public.pengaturan_layanan;
create policy layanan_write on public.pengaturan_layanan for all to authenticated
  using (mitra_id = auth.uid()) with check (mitra_id = auth.uid());

-- ---------------------------------------------------------------------
-- 10. Row Level Security
-- ---------------------------------------------------------------------
alter table public.orders enable row level security;
alter table public.mitra_locations enable row level security;
alter table public.messages enable row level security;
alter table public.ratings enable row level security;
alter table public.wallet_tx enable row level security;
alter table public.withdrawals enable row level security;
alter table public.sos_events enable row level security;
alter table public.mitra_documents enable row level security;

drop policy if exists orders_read on public.orders;
create policy orders_read on public.orders for select to authenticated using (true);

drop policy if exists orders_insert_warga on public.orders;
create policy orders_insert_warga on public.orders for insert to authenticated
  with check (customer_id = auth.uid());

drop policy if exists orders_update_mitra on public.orders;
create policy orders_update_mitra on public.orders for update to authenticated
  using (mitra_id = auth.uid() or status = 'pending')
  with check (mitra_id = auth.uid() or status = 'pending');

drop policy if exists lokasi_read on public.mitra_locations;
create policy lokasi_read on public.mitra_locations for select to authenticated using (true);

drop policy if exists lokasi_write on public.mitra_locations;
create policy lokasi_write on public.mitra_locations for all to authenticated
  using (mitra_id = auth.uid()) with check (mitra_id = auth.uid());

drop policy if exists pesan_read on public.messages;
create policy pesan_read on public.messages for select to authenticated using (true);

drop policy if exists pesan_write on public.messages;
create policy pesan_write on public.messages for insert to authenticated
  with check (sender_id = auth.uid());

drop policy if exists rating_read on public.ratings;
create policy rating_read on public.ratings for select to authenticated using (true);

drop policy if exists rating_insert on public.ratings;
create policy rating_insert on public.ratings for insert to authenticated
  with check (customer_id = auth.uid());

drop policy if exists rating_reply on public.ratings;
create policy rating_reply on public.ratings for update to authenticated
  using (mitra_id = auth.uid()) with check (mitra_id = auth.uid());

drop policy if exists wallet_read on public.wallet_tx;
create policy wallet_read on public.wallet_tx for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists tarik_read on public.withdrawals;
create policy tarik_read on public.withdrawals for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists tarik_insert on public.withdrawals;
create policy tarik_insert on public.withdrawals for insert to authenticated
  with check (mitra_id = auth.uid());

drop policy if exists sos_read on public.sos_events;
create policy sos_read on public.sos_events for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists sos_insert on public.sos_events;
create policy sos_insert on public.sos_events for insert to authenticated
  with check (mitra_id = auth.uid());

drop policy if exists dokumen_read on public.mitra_documents;
create policy dokumen_read on public.mitra_documents for select to authenticated
  using (mitra_id = auth.uid());

drop policy if exists dokumen_insert on public.mitra_documents;
create policy dokumen_insert on public.mitra_documents for insert to authenticated
  with check (mitra_id = auth.uid());

-- profiles: mitra hanya boleh mengubah barisnya sendiri
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- ---------------------------------------------------------------------
-- 11. Realtime - supaya order masuk tanpa refresh
-- ---------------------------------------------------------------------
do $$
begin
  begin
    alter publication supabase_realtime add table public.orders;
  exception when duplicate_object then null; end;
  begin
    alter publication supabase_realtime add table public.messages;
  exception when duplicate_object then null; end;
  begin
    alter publication supabase_realtime add table public.mitra_locations;
  exception when duplicate_object then null; end;
  begin
    alter publication supabase_realtime add table public.ratings;
  exception when duplicate_object then null; end;
  begin
    alter publication supabase_realtime add table public.notifikasi_mitra;
  exception when duplicate_object then null; end;
  begin
    alter publication supabase_realtime add table public.chat_rooms;
  exception when duplicate_object then null; end;
end $$;

-- ---------------------------------------------------------------------
-- 12. CONTOH DATA (opsional, untuk uji)
-- ---------------------------------------------------------------------
-- Jadikan akun yang sudah daftar jadi mitra + terverifikasi:
--   update public.profiles set role = 'mitra', vehicle_type = 'Motor',
--     plate = 'B 1234 XYZ', verified = true
--   where id = (select id from auth.users where email = 'mitra@contoh.id');
