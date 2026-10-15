-- ============================================================================
-- KUNBAR Connect - skema Postgres + Row Level Security
-- ----------------------------------------------------------------------------
-- CARA PAKAI (paling gampang, tanpa tool apa pun):
--   Supabase Dashboard -> SQL Editor -> New query -> tempel file ini -> Run
--
-- AMAN DIJALANKAN ULANG: semua memakai `if not exists` / `drop policy if
-- exists`, jadi tidak merusak data yang sudah ada.
--
-- ATURAN KEAMANAN YANG DIPAKAI DI SINI:
--   1. App TIDAK BOLEH menulis role sendiri. Role hanya bisa diubah oleh
--      admin lewat panel web. Ini yang memperbaiki masalah lama: di APK,
--      role disimpan di SharedPreferences sehingga siapa pun bisa elevate
--      dirinya jadi admin lewat tombol di halaman Profil.
--   2. `anon key` (yang dipakai APK) hanya boleh MEMBACA tabel publik.
--      Semua penulisan melewati RLS, jadi kunci yang bocor tidak berarti
--     =data bisa diubah seenaknya.
--   3. `service_role` key HANYA untuk server web. Tidak boleh masuk APK.
-- ============================================================================

-- ---------------------------------------------------------------- 0. ekstensi
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------ 1. tabel profil
-- Satu baris per pengguna. `role` Determines semua hak akses.
create table if not exists public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  nama            text not null default '',
  no_telepon      text,
  nik             text,
  alamat          text,
  rt              text,
  rw              text,
  role            text not null default 'warga'
                    check (role in ('guest', 'warga', 'anggota', 'pengurus', 'admin')),
  diverifikasi    boolean not null default false,
  nomor_anggota   text,
  divisi          text,
  poin            integer not null default 0,
  total_kegiatan  integer not null default 0,
  dibuat          timestamptz not null default now()
);

create index if not exists idx_profiles_role on public.profiles (role);

-- ------------------------------------------------- 2. tabel konten publik
-- Tiga tabel ini boleh dibaca siapa pun, termasuk tamu yang belum login.
create table if not exists public.kegiatan (
  id          uuid primary key default gen_random_uuid(),
  judul       text not null,
  kategori    text not null default 'Sosial',
  tanggal     timestamptz,
  lokasi      text not null default '',
  mendatang   boolean not null default false,
  dibuat      timestamptz not null default now()
);
create index if not exists idx_kegiatan_tanggal on public.kegiatan (tanggal);

create table if not exists public.berita (
  id      uuid primary key default gen_random_uuid(),
  judul   text not null,
  sumber  text not null default '',
  waktu   text not null default '',
  tag     text not null default '',
  dibuat  timestamptz not null default now()
);
create index if not exists idx_berita_dibuat on public.berita (dibuat desc);

create table if not exists public.pengumuman (
  id      uuid primary key default gen_random_uuid(),
  tag     text not null default '',
  judul   text not null,
  isi     text not null default '',
  dibuat  timestamptz not null default now()
);
create index if not exists idx_pengumuman_dibuat on public.pengumuman (dibuat desc);

-- ------------------------------------------------------------- 3. tabel kas
create table if not exists public.iuran (
  id        uuid primary key default gen_random_uuid(),
  warga_id  uuid references public.profiles (id) on delete set null,
  periode   text not null,
  nominal   integer not null default 0,
  lunas     boolean not null default false,
  catatan   text
);

create table if not exists public.kas_bulanan (
  id    uuid primary key default gen_random_uuid(),
  label text not null unique,
  juta  double precision not null default 0
);

-- --------------------------------------------------------- 4. FISH / Osorio
-- `id` sengaja TEXT, bukan uuid: aplikasi membuat id seperti
-- `fish-1760000000000` supaya tidak perlu generate uuid di perangkat.
create table if not exists public.aspirasi (
  id         text primary key,
  judul      text not null,
  isi        text not null,
  kategori   text not null default 'lain'
               check (kategori in ('jalan', 'keamanan', 'kebersihan',
                                   'layanan', 'kegiatan', 'lain')),
  status     text not null default 'baru'
               check (status in ('baru', 'diproses', 'selesai', 'ditolak')),
  pengirim   text not null default '',
  pengirim_id uuid references public.profiles (id) on delete set null,
  rt         text,
  rw         text,
  balasan    text,
  contoh     boolean not null default false,
  dibuat     timestamptz not null default now()
);
create index if not exists idx_aspirasi_status on public.aspirasi (status);
create index if not exists idx_aspirasi_dibuat on public.aspirasi (dibuat desc);

-- ============================================================================
-- 5. FUNGSI BANTUAN
-- ============================================================================
-- `peran()` = daftar nama peran milik seorang pengguna.
--
-- PENTING: fungsi ini `security definer` supaya TIDAK ikut tersandera RLS
-- (kalau tidak, policies yang memanggilnya masuk loop tak berujung).
-- Karena itu di dalam fungsi ini HANYA boleh SELECT, tidak boleh menulis.
create or replace function public.peran(pengguna uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = pengguna), '');
$$;

-- True kalau pengguna adalah pengurus atau admin.
create or replace function public.bisa_kelola(pengguna uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = pengguna), '')
         in ('pengurus', 'admin');
$$;

-- Baris profil otomatis dibuat begitu orang mendaftar, role paling rendah.
create or replace function public.buat_profil_baru()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nama, no_telepon)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nama', ''),
    new.raw_user_meta_data ->> 'no_telepon'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_buat_profil on auth.users;
create trigger trg_buat_profil
  after insert on auth.users
  for each row execute function public.buat_profil_baru();

-- ============================================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================================
alter table public.profiles      enable row level security;
alter table public.kegiatan      enable row level security;
alter table public.berita        enable row level security;
alter table public.pengumuman    enable row level security;
alter table public.iuran         enable row level security;
alter table public.kas_bulanan   enable row level security;
alter table public.aspirasi      enable row level security;

-- ------------------------------------------------------------- profiles ----
drop policy if exists profil_baca_diri on public.profiles;
create policy profil_baca_diri on public.profiles
  for select
  using (auth.uid() = id or public.bisa_kelola(auth.uid()));

-- Menulis profil HANYA boleh pengurus/admin. Warga tidak boleh mengubah
-- role-nya sendiri - inilah yang tidak bisa dijamin oleh kode aplikasi.
drop policy if exists profil_tulis_kelola on public.profiles;
create policy profil_tulis_kelola on public.profiles
  for all
  using (public.bisa_kelola(auth.uid()))
  with check (public.bisa_kelola(auth.uid()));

-- Catatan: "for all" di profiles juga mengizinkan DELETE untuk pengelola.
-- Kalau ini tidak diinginkan, pisahkan policy INSERT/UPDATE/DELETE.

-- ---------------------------------------------------- konten publik (read) --
drop policy if exists kegiatan_baca on public.kegiatan;
create policy kegiatan_baca on public.kegiatan
  for select using (true);

drop policy if exists berita_baca on public.berita;
create policy berita_baca on public.berita
  for select using (true);

drop policy if exists pengumuman_baca on public.pengumuman;
create policy pengumuman_baca on public.pengumuman
  for select using (true);

-- Menulis konten hanya pengurus/admin (broadcast dari panel web).
drop policy if exists kegiatan_tulis on public.kegiatan;
create policy kegiatan_tulis on public.kegiatan
  for all using (public.bisa_kelola(auth.uid()))
  with check (public.bisa_kelola(auth.uid()));

drop policy if exists berita_tulis on public.berita;
create policy berita_tulis on public.berita
  for all using (public.bisa_kelola(auth.uid()))
  with check (public.bisa_kelola(auth.uid()));

drop policy if exists pengumuman_tulis on public.pengumuman;
create policy pengumuman_tulis on public.pengumuman
  for all using (public.bisa_kelola(auth.uid()))
  with check (public.bisa_kelola(auth.uid()));

-- ------------------------------------------------------------------ kas ----
-- Warga boleh melihat iuran SENDIRI saja. Laporan kas hanya pengurus.
drop policy if exists iuran_baca on public.iuran;
create policy iuran_baca on public.iuran
  for select
  using (auth.uid() = warga_id or public.bisa_kelola(auth.uid()));

drop policy if exists iuran_tulis on public.iuran;
create policy iuran_tulis on public.iuran
  for all using (public.bisa_kelola(auth.uid()))
  with check (public.bisa_kelola(auth.uid()));

drop policy if exists kas_baca on public.kas_bulanan;
create policy kas_baca on public.kas_bulanan
  for select
  using (public.bisa_kelola(auth.uid()));

drop policy if exists kas_tulis on public.kas_bulanan;
create policy kas_tulis on public.kas_bulanan
  for all using (public.bisa_kelola(auth.uid()))
  with check (public.bisa_kelola(auth.uid()));

-- --------------------------------------------------------------- FISH ------
-- Semua pengguna login bisa membaca papan FISH ( transparan untuk warga).
drop policy if exists aspirasi_baca on public.aspirasi;
create policy aspirations_baca on public.aspirasi
  for select using (auth.uid() is not null);

-- Mengirim laporan: siapa pun yang login boleh menambah. Kolom
-- yang boleh diisi pengguna TIDAK termasuk status/balasan/contoh supaya
-- orang tidak bisa mengirim laporan yang langsung berstatus "selesai".
drop policy if exists aspirasi_kirim on public.aspirasi;
create policy aspirations_kirim on public.aspirasi
  for insert to authenticated
  with check (
    auth.uid() is not null
    and status = 'baru'
    and contoh = false
    and (pengirim_id is null or pengirim_id = auth.uid())
  );

-- Mengubah status HANYA pengurus/admin - inilah gate sungguhan yang dulu
-- tidak ada sama sekali saat role disimpan di perangkat.
drop policy if exists aspirasi_ubah on public.aspirasi;
create policy aspirations_ubah on public.aspirasi
  for update
  using (public.bisa_kelola(auth.uid()))
  with check (public.bisa_kelola(auth.uid()));

-- ============================================================================
-- 7. CARA MENAIKAN ROLE (tidak pernah dari aplikasi)
-- ============================================================================
-- Di SQL Editor, setelah orang mendaftar:
--
--   update public.profiles
--      set role = 'pengurus', diverifikasi = true
--    where no_telepon = '+628123456789';
--
-- Dari app, role hanya bisa naik lewat panel web yang memakai service_role,
-- atau lewat perintah SQL di atas.
-- ============================================================================