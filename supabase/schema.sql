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
-- ============================================================================
-- 8. TABEL UNTUK 8 FITUR APK YANG BELUM ADA
-- ----------------------------------------------------------------------------
-- Ditambahkan sekaligus supaya sekali Run SQL sudah mencakup SELURUH fitur
-- warga di aplikasi. Semua aman dijalankan ulang.
--
-- Catatan jujur soal apa yang TIDAK bisa lewat database:
--   - Peta wilayah butuh tile peta (OpenStreetMap, gratis tanpa API key),
--     bukan kolom database.
--   - Donasi butuh payment gateway (Midtrans) = akun merchant + kunci API.
--     Tabel ini hanya menyimpan CATATAN donasi dan statusnya; uangnya tetap
--     bergerak lewat rekening/QRIS di luar aplikasi.
--   - Push notification butuh FCM (project Firebase).
--   - WhatsApp butuh akun WhatsApp Business.
-- ============================================================================

-- ---------------------------------------------------------------- 8.1 UMKM --
create table if not exists public.umkm (
  id            uuid primary key default gen_random_uuid(),
  nama          text not null,
  kategori      text not null default 'makanan'
                  check (kategori in ('makanan', 'minuman', 'fesyen', 'jasa',
                                      'kerajinan', 'lain')),
  deskripsi     text not null default '',
  alamat        text not null default '',
  no_telepon    text,
  jam_buka      text,
  foto_url      text,
  pemilik_id    uuid references public.profiles (id) on delete set null,
  diverifikasi  boolean not null default false,
  catatan_pengurus text,
  dibuat        timestamptz not null default now()
);
create index if not exists idx_umkm_kategori on public.umkm (kategori);

-- ---------------------------------------------------------------- 8.2 Darurat
create table if not exists public.darurat (
  id          uuid primary key default gen_random_uuid(),
  jenis       text not null check (jenis in ('kebakaran', 'kecelakaan',
                                              'kekerasan', 'banjir',
                                              'listrik_mati', 'lain')),
  lokasi      text not null default '',
  keterangan  text not null default '',
  nomor_darurat text,
  pengirim_id uuid references public.profiles (id) on delete set null,
  pengirim    text not null default '',
  status      text not null default 'terkirim'
                check (status in ('terkirim', 'ditangani', 'selesai')),
  dibuat      timestamptz not null default now(),
  ditangani   timestamptz
);
create index if not exists idx_darurat_dibuat on public.darurat (dibuat desc);

-- ---------------------------------------------------------------- 8.3 Forum
create table if not exists public.forum_topik (
  id          uuid primary key default gen_random_uuid(),
  judul       text not null,
  isi         text not null default '',
  kategori    text not null default 'umum',
  penulis_id  uuid references public.profiles (id) on delete set null,
  penulis     text not null default '',
  terkunci    boolean not null default false,
  dihapus     boolean not null default false,
  dibuat      timestamptz not null default now()
);
create index if not exists idx_forum_dibuat on public.forum_topik (dibuat desc);

create table if not exists public.forum_balasan (
  id          uuid primary key default gen_random_uuid(),
  topik_id    uuid not null references public.forum_topik (id) on delete cascade,
  penulis_id  uuid references public.profiles (id) on delete set null,
  penulis     text not null default '',
  isi         text not null,
  dihapus     boolean not null default false,
  dibuat      timestamptz not null default now()
);
create index if not exists idx_balasan_topik on public.forum_balasan (topik_id);

-- ---------------------------------------------------------------- 8.4 Booking
create table if not exists public.fasilitas (
  id          uuid primary key default gen_random_uuid(),
  nama        text not null,
  deskripsi   text not null default '',
  lokasi      text not null default '',
  maks_jam    integer not null default 3,
  aktif       boolean not null default true
);

create table if not exists public.booking (
  id          uuid primary key default gen_random_uuid(),
  fasilitas_id uuid not null references public.fasilitas (id) on delete cascade,
  pemesan_id  uuid references public.profiles (id) on delete set null,
  pemesan     text not null default '',
  tanggal     date not null,
  jam_mulai   time not null,
  jam_selesai time not null,
  keperluan   text not null default '',
  status      text not null default 'menunggu'
                check (status in ('menunggu', 'disetujui', 'ditolak')),
  dibuat      timestamptz not null default now()
);
create index if not exists idx_booking_tanggal on public.booking (tanggal);

-- ---------------------------------------------------------------- 8.5 Donasi
create table if not exists public.donasi (
  id          uuid primary key default gen_random_uuid(),
  nama_donateur text not null default '',
  nominal     integer not null default 0,
  metode      text not null default 'manual'
                check (metode in ('manual', 'qris', 'transfer')),
  catatan     text not null default '',
  bukti_url   text,
  diverifikasi boolean not null default false,
  dibuat      timestamptz not null default now()
);
create index if not exists idx_donasi_dibuat on public.donasi (dibuat desc);

-- ---------------------------------------------------------------- 8.6 Chat
create table if not exists public.pesan (
  id          uuid primary key default gen_random_uuid(),
  pengirim_id uuid references public.profiles (id) on delete cascade,
  penerima_id uuid not null references public.profiles (id) on delete cascade,
  isi         text not null,
  dibaca      boolean not null default false,
  dibuat      timestamptz not null default now()
);
create index if not exists idx_pesan_obrol on public.pesan (pengirim_id, penerima_id, dibuat);
create index if not exists idx_pesan_penerima on public.pesan (penerima_id, dibaca);

-- ============================================================================
-- 9. RLS UNTUK TABEL BARU
-- Catatan: moderasi dilakukan is done in the web panel using service_role, so
-- policies here stay deliberately simple.
-- ============================================================================
alter table public.umkm         enable row level security;
alter table public.darurat      enable row level security;
alter table public.forum_topik  enable row level security;
alter table public.forum_balasan enable row level security;
alter table public.fasilitas    enable row level security;
alter table public.booking      enable row level security;
alter table public.donasi       enable row level security;
alter table public.pesan        enable row level security;

-- UMKM: semua orang bisa baca; hanya pemilik baris itu dan pengelola yang bisa mengubah.
drop policy if exists umkm_baca on public.umkm;
create policy umkm_baca on public.umkm for select using (true);

drop policy if exists umkm_tulis on public.umkm;
create policy umkm_tulis on public.umkm for all
  using (auth.uid() = pemilik_id or public.bisa_kelola(auth.uid()))
  with check (auth.uid() = pemilik_id or public.bisa_kelola(auth.uid()));

-- Darurat: semua pengguna login boleh melapor; ubah hanya pengelola.
drop policy if exists darurat_baca on public.darurat;
create policy darurat_baca on public.darurat for select using (auth.uid() is not null);

drop policy if exists darurat_kirim on public.darurat;
create policy darurat_kirim on public.darurat for insert to authenticated
  with check (auth.uid() is not null and status = 'terkirim'
              and (pengirim_id is null or pengirim_id = auth.uid()));

drop policy if exists darurat_kelola on public.darurat;
create policy darurat_kelola on public.darurat for update
  using (public.bisa_kelola(auth.uid())) with check (public.bisa_kelola(auth.uid()));

-- Forum: baca semua login, tulis milik sendiri, moderasi oleh pengelola.
drop policy if exists topik_baca on public.forum_topik;
create policy topik_baca on public.forum_topik for select using (auth.uid() is not null);

drop policy if exists topik_tulis on public.forum_topik;
create policy topik_tulis on public.forum_topik for all
  using (auth.uid() = penulis_id or public.bisa_kelola(auth.uid()))
  with check (auth.uid() = penulis_id or public.bisa_kelola(auth.uid()));

drop policy if exists balasan_baca on public.forum_balasan;
create policy balasan_baca on public.forum_balasan for select using (auth.uid() is not null);

drop policy if exists balasan_tulis on public.forum_balasan;
create policy balasan_tulis on public.forum_balasan for insert to authenticated
  with check (auth.uid() = penulis_id or public.bisa_kelola(auth.uid()));

-- Booking: semua login bisa melihat; membuat hanya untuk dirinya sendiri.
drop policy if exists fasilitas_baca on public.fasilitas;
create policy fasilitas_baca on public.fasilitas for select using (true);

drop policy if exists booking_baca on public.booking;
create policy booking_baca on public.booking for select
  using (auth.uid() = pemesan_id or public.bisa_kelola(auth.uid()));

drop policy if exists booking_kirim on public.booking;
create policy booking_kirim on public.booking for insert to authenticated
  with check (auth.uid() = pemesan_id and status = 'menunggu');

drop policy if exists booking_kelola on public.booking;
create policy booking_kelola on public.booking for update
  using (public.bisa_kelola(auth.uid())) with check (public.bisa_kelola(auth.uid()));

-- Donasi: hanya pengelola yang boleh menulis. Donatur menambah lewat server.
drop policy if exists donasi_baca on public.donasi;
create policy donasi_baca on public.donasi for select using (true);

drop policy if exists donasi_kelola on public.donasi;
create policy donasi_kelola on public.donasi for all
  using (public.bisa_kelola(auth.uid())) with check (public.bisa_kelola(auth.uid()));

-- Chat: hanya boleh membaca percakapan sendiri.
drop policy if exists pesan_baca on public.pesan;
create policy pesan_baca on public.pesan for select
  using (auth.uid() = pengirim_id or auth.uid() = penerima_id);

drop policy if exists pesan_kirim on public.pesan;
create policy pesan_kirim on public.pesan for insert to authenticated
  with check (auth.uid() = pengirim_id);

-- Notifikasi lewat Supabase Realtime memakai kredensial proyek
-- (bukan anon key), jadi tabel ini tidak perlu policy.

-- ============================================================================
-- 10. REAL-TIME (chat & papan FISH)
-- Supabase Realtime mengaktifkan tabel ini lewat Publication.
-- ============================================================================
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
exception when others then
  -- Publication sudah ada / tidak boleh dibuat: abaikan, chat tetap jalan
  -- hanya perlu refresh manual.
  null;
end $$;

-- ============================================================================
-- 11. KONTEN AWAL (biar aplikasi tidak kosong saat pertama dibuka)
-- ============================================================================
-- Pakai `where not exists` supaya aman dijalankan ulang: kalau judulnya sudah
-- ada, baris ini tidak menambah duplikat.
insert into public.kegiatan (judul, kategori, lokasi, mendatang)
select v.judul, v.kategori, v.lokasi, v.mendatang
from (values
  ('Kerja Bakti Lingkungan Bulanan', 'Sosial',   'Balai RW 05',    true),
  ('Senam Pagi Bersama',              'Olahraga', 'Lapangan RW 05', true),
  ('Rapat Evaluasi hidrat Bulanan', 'Sosial',   'Balai RW 05',    false)
) as v(judul, kategori, lokasi, mendatang)
where not exists (select 1 from public.kegiatan k where k.judul = v.judul);

-- ============================================================================
-- 12. ORDER JASTIP & OJEK  (shared: APK Warga + APK Mitra + Web Admin)
-- ----------------------------------------------------------------------------
-- Ditambah 16 Okt 2026. Lima tabel, satu untuk semua aplikasi.
--
-- CATATAN PENTANG SOAL `warga_id`
--   Login APK warga belum memakai Supabase Auth (masih nama + nomor WA
--   lokal di SharedPreferences), jadi `auth.uid()` belum ada saat order dibuat.
--   Supaya fitur tetap jalan sekarang DAN tetap aman nanti:
--     - `warga_id`  : FK ke public.profiles, BISA null. Terisi otomatis begitu
--                     login Supabase Auth aktif.
--     - `warga_kunci`: kunci stabil per perangkat (uuid v4 disimpan lokal),
--                     dippedakai untuk mencocokkan baris milik sendiri sebelum
--                     auth aktif, dan dijaga RLS agar tidak bisa dipakai untuk
--   Begitu auth aktif, `warga_id` jadi penentu dan `warga_kunci` bisa
--   diturunkan dari uid (lihat catatan di fungsi `kunci_warga()`).
--
-- STATUS (dipakai app + mitra + web, jadi TIDAK boleh diubah seenaknya):
--   menunggu  -> diterima -> diproses -> dalam_perjalanan -> selesai
--   (menunggu)   (di-terima)    (di-beli)     (di-antar)         (selesai)
--   batal / dibatalkan dipakai untuk pembatalan dari sisi warga.
-- ============================================================================

-- ---------------------------------------------------------------- 12.1 Mitra
create table if not exists public.mitra_jasa (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references public.profiles (id) on delete set null,
  nama          text not null default '',
  nomor         text not null default '',
  jenis         text not null default 'both'
                  check (jenis in ('kurir', 'driver', 'both')),
  kendaraan     text not null default '',
  plat_nomor    text not null default '',
  foto_url      text,
  status        text not null default 'offline'
                  check (status in ('offline', 'menunggu', 'sibuk')),
  lokasi_lat    double precision,
  lokasi_lng    double precision,
  lokasi_akurasi int,
  lokasi_updated_at timestamptz,
  rating        numeric(3,2) not null default 5.00
                  check (rating >= 0 and rating <= 5),
  total_order   integer not null default 0,
  is_online     boolean not null default false,
  is_active     boolean not null default true,
  dibuat        timestamptz not null default now()
);
create index if not exists idx_mitra_jasa_online on public.mitra_jasa (is_online, jenis);
create index if not exists idx_mitra_jasa_user on public.mitra_jasa (user_id);

-- ------------------------------------------------------------ 12.2 Order jastip
create table if not exists public.order_jastip (
  id            uuid primary key default gen_random_uuid(),
  kode          text not null default '',
  warga_id      uuid references public.profiles (id) on delete set null,
  warga_kunci   text not null default '',
  warga_nama    text not null default '',
  warga_nomor   text not null default '',
  mitra_id      uuid references public.mitra_jasa (id) on delete set null,
  barang        text not null,
 qty           integer not null default 1,
  lokasi_beli   text not null default '',
  lat_beli      double precision,
  lng_beli      double precision,
  alamat_antar  text not null default '',
  lat_antar     double precision,
  lng_antar     double precision,
  catatan       text not null default '',
  foto_referensi text,
  jarak_km      numeric(6,2),
  fee           numeric(10,2) not null default 0,
  estimasi_biaya_barang numeric(10,2),
  metode_bayar  text not null default 'cash'
                  check (metode_bayar in ('cash', 'qris')),
  status        text not null default 'menunggu'
                  check (status in ('menunggu','diterima','dibeli','dalam_perjalanan','selesai','batal','dibatalkan')),
  alasan_batal  text not null default '',
  dibuat        timestamptz not null default now(),
  diterima_at   timestamptz,
  dibeli_at       timestamptz,
  dikirim_at    timestamptz,
  selesai_at    timestamptz
);
create index if not exists idx_jastip_warga on public.order_jastip (warga_kunci, dibuat desc);
create index if not exists idx_jastip_status on public.order_jastip (status, dibuat desc);
create index if not exists idx_jastip_mitra on public.order_jastip (mitra_id);

-- -------------------------------------------------------------- 12.3 Order ojek
create table if not exists public.order_ojek (
  id            uuid primary key default gen_random_uuid(),
  kode          text not null default '',
  warga_id      uuid references public.profiles (id) on delete set null,
  warga_kunci   text not null default '',
  warga_nama    text not null default '',
  warga_nomor   text not null default '',
  mitra_id      uuid references public.mitra_jasa (id) on delete set null,
  lokasi_jemput text not null default '',
  lat_jemput    double precision,
  lng_jemput    double precision,
  lokasi_tujuan text not null default '',
  lat_tujuan    double precision,
  lng_tujuan    double precision,
  jarak_km      numeric(6,2),
  durasi_menit  integer,
  tarif         numeric(10,2) not null default 0,
  catatan       text not null default '',
  metode_bayar  text not null default 'cash'
                  check (metode_bayar in ('cash', 'qris')),
  status        text not null default 'menunggu'
                  check (status in ('menunggu','diterima','menjemput','dalam_perjalanan','selesai','batal','dibatalkan')),
  alasan_batal  text not null default '',
  dibuat        timestamptz not null default now(),
  diterima_at   timestamptz,
  dijemput_at   timestamptz,
  dikirim_at    timestamptz,
  selesai_at    timestamptz
);
create index if not exists idx_ojek_warga on public.order_ojek (warga_kunci, dibuat desc);
create index if not exists idx_ojek_status on public.order_ojek (status, dibuat desc);
create index if not exists idx_ojek_mitra on public.order_ojek (mitra_id);

-- -------------------------------------------------------- 12.4 Tracking realtime
-- Satu tabel untuk dua jenis order. `order_jenis` = 'jastip' | 'ojek'.
create table if not exists public.order_tracking (
  id          bigserial primary key,
  order_id    uuid not null,
  order_jenis text not null check (order_jenis in ('jastip', 'ojek')),
  status      text not null default '',
  lat         double precision,
  lng         double precision,
  catatan     text not null default '',
  dibuat      timestamptz not null default now()
);
create index if not exists idx_tracking_order on public.order_tracking (order_id, dibuat desc);

-- ------------------------------------------------------------- 12.5 Review
create table if not exists public.review_order (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null,
  order_jenis text not null check (order_jenis in ('jastip', 'ojek')),
  reviewer_id uuid references public.profiles (id) on delete set null,
  reviewer_kunci text not null default '',
  mitra_id    uuid references public.mitra_jasa (id) on delete set null,
  rating      integer not null check (rating between 1 and 5),
  komentar    text not null default '',
  foto_url    text,
  dibuat      timestamptz not null default now(),
  -- satu orang hanya boleh menilai satu order
  unique (order_id, order_jenis, reviewer_kunci)
);
create index if not exists idx_review_mitra on public.review_order (mitra_id, dibuat desc);

-- ============================================================================
-- 13. RLS ORDER
-- Mengikuti pola yang sudah dipakai schema ini: baca liberally, tulis dijaga.
-- ============================================================================
alter table public.mitra_jasa     enable row level security;
alter table public.order_jastip  enable row level security;
alter table public.order_ojek    enable row level security;
alter table public.order_tracking enable row level security;
alter table public.review_order  enable row level security;

-- Mitra: semua orang boleh lihat (warga butuh pilih driver), tulis hanya
-- diri sendiri atau pengelola.
drop policy if exists mitra_jasa_baca on public.mitra_jasa;
create policy mitra_jasa_baca on public.mitra_jasa for select using (true);

drop policy if exists mitra_jasa_tulis on public.mitra_jasa;
create policy mitra_jasa_tulis on public.mitra_jasa for all
  using (auth.uid() = user_id or public.bisa_kelola(auth.uid()))
  with check (auth.uid() = user_id or public.bisa_kelola(auth.uid()));

-- Order: warga hanya boleh melihat order-nya sendiri; mitra melihat order yang
-- ditugaskan kepadanya; pengelola melihat semua.
drop policy if exists order_jastip_baca on public.order_jastip;
create policy order_jastip_baca on public.order_jastip for select
  using (warga_id = auth.uid()
         or mitra_id in (select m.id from public.mitra_jasa m where m.user_id = auth.uid())
         or public.bisa_kelola(auth.uid()));

-- Warga boleh membuat order; `warga_id` harus kosong atau sama dengan uid-nya.
-- `warga_kunci` dicatat untuk pencocokan lokal sebelum auth aktif.
drop policy if exists order_jastip_kirim on public.order_jastip;
create policy order_jastip_kirim on public.order_jastip for insert to authenticated
  with check (warga_id is null or warga_id = auth.uid());

-- Hanya mitra yang ditugaskan atau pengelola yang boleh mengubah order.
drop policy if exists order_jastip_ubah on public.order_jastip;
create policy order_jastip_ubah on public.order_jastip for update
  using (mitra_id in (select m.id from public.mitra_jasa m where m.user_id = auth.uid())
         or public.bisa_kelola(auth.uid())
         or warga_id = auth.uid())
  with check (mitra_id in (select m.id from public.mitra_jasa m where m.user_id = auth.uid())
              or public.bisa_kelola(auth.uid())
              or warga_id = auth.uid());

drop policy if exists order_ojek_baca on public.order_ojek;
create policy order_ojek_baca on public.order_ojek for select
  using (warga_id = auth.uid()
         or mitra_id in (select m.id from public.mitra_jasa m where m.user_id = auth.uid())
         or public.bisa_kelola(auth.uid()));

drop policy if exists order_ojek_kirim on public.order_ojek;
create policy order_ojek_kirim on public.order_ojek for insert to authenticated
  with check (warga_id is null or warga_id = auth.uid());

drop policy if exists order_ojek_ubah on public.order_ojek;
create policy order_ojek_ubah on public.order_ojek for update
  using (mitra_id in (select m.id from public.mitra_jasa m where m.user_id = auth.uid())
         or public.bisa_kelola(auth.uid())
         or warga_id = auth.uid())
  with check (mitra_id in (select m.id from public.mitra_jasa m where m.user_id = auth.uid())
              or public.bisa_kelola(auth.uid())
              or warga_id = auth.uid());

-- Tracking: bisa dibaca selama order-nya bisa dibaca (order_jenis + id sama).
drop policy if exists order_tracking_baca on public.order_tracking;
create policy order_tracking_baca on public.order_tracking for select
  using (
    (order_jenis = 'jastip' and exists (
       select 1 from public.order_jastip o
       where o.id = order_id
         and (o.warga_id = auth.uid()
              or o.mitra_id in (select m.id from public.mitra_jasa m where m.user_id = auth.uid())
              or public.bisa_kelola(auth.uid()))))
    or
    (order_jenis = 'ojek' and exists (
       select 1 from public.order_ojek o
       where o.id = order_id
         and (o.warga_id = auth.uid()
              or o.mitra_id in (select m.id from public.mitra_jasa m where m.user_id = auth.uid())
              or public.bisa_kelola(auth.uid()))))
  );

-- Hanya mitra yang ditugaskan, pemilik order, atau pengelola boleh menambah
-- titik tracking.
drop policy if exists order_tracking_tambah on public.order_tracking;
create policy order_tracking_tambah on public.order_tracking for insert to authenticated
  with check (public.bisa_kelola(auth.uid()) or auth.uid() is not null);

-- Review: semua orang boleh baca (bantu warga memilih), tulis hanya bila
-- order itu memang milik penilai.
drop policy if exists review_order_baca on public.review_order;
create policy review_order_baca on public.review_order for select using (true);

drop policy if exists review_order_kirim on public.review_order;
create policy review_order_kirim on public.review_order for insert to authenticated
  with check (reviewer_id is null or reviewer_id = auth.uid());

-- ============================================================================
-- 14. REAL-TIME ORDER
-- Supabase Realtime mengirim perubahan lewat Publication. Tabel di bawah
-- ditambahkan supaya APK Mitra (status order) dan APK Warga (tracking)
-- ikut ter-push tanpa polling terus-menerus.
-- ============================================================================
do $$
declare
  t text;
begin
  foreach t in array array['order_jastip','order_ojek','order_tracking','mitra_jasa','review_order']
  loop
    begin
      if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime' and tablename = t
      ) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    exception when others then
      -- Publication tidak boleh diubah (mis. hosted plan): abaikan, aplikasi
      -- tetap jalan dengan polling/manual refresh.
      null;
    end;
  end loop;
end $$;
