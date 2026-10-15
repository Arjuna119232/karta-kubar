-- KUNBAR Mitra - skema Supabase. Jalankan di SQL Editor.
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  role text not null default 'warga' check (role in ('warga','mitra','admin')),
  name text, phone text,
  vehicle_type text, vehicle_model text, plate text,
  is_online boolean default false,
  radius_km numeric default 5, open_hour int default 6, close_hour int default 22,
  fcm_token text,
  created_at timestamptz default now()
);

create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('jastip','ojek')),
  customer_id uuid references profiles(id),
  mitra_id uuid references profiles(id),
  customer_name text, customer_phone text,
  pickup_address text, drop_address text,
  pickup_lat double precision, pickup_lng double precision,
  drop_lat double precision, drop_lng double precision,
  distance_km numeric, fee int, note text,
  status text not null default 'pending'
    check (status in ('pending','accepted','arrived','delivering','done','cancelled')),
  created_at timestamptz default now(), completed_at timestamptz
);

create table if not exists messages (
  id bigint generated always as identity primary key,
  order_id uuid references orders on delete cascade,
  sender_id uuid references profiles,
  body text not null, created_at timestamptz default now()
);
create table if not exists ratings (
  id bigint generated always as identity primary key,
  order_id uuid references orders, mitra_id uuid references profiles,
  stars int check (stars between 1 and 5), comment text,
  created_at timestamptz default now()
);
create table if not exists mitra_locations (
  order_id uuid primary key references orders on delete cascade,
  mitra_id uuid references profiles,
  lat double precision, lng double precision, updated_at timestamptz default now()
);
create table if not exists sos_events (
  id bigint generated always as identity primary key,
  mitra_id uuid references profiles, order_id uuid,
  lat double precision, lng double precision,
  handled boolean default false, created_at timestamptz default now()
);
create table if not exists wallet_tx (
  id bigint generated always as identity primary key,
  mitra_id uuid references profiles, amount int not null,
  kind text not null, note text, created_at timestamptz default now()
);

-- Mitra tidak boleh mengubah role-nya sendiri
revoke update on profiles from authenticated;
grant update (name, phone, vehicle_type, vehicle_model, plate, is_online,
              radius_km, open_hour, close_hour, fcm_token) on profiles to authenticated;

alter table profiles enable row level security;
alter table orders enable row level security;
alter table messages enable row level security;
alter table ratings enable row level security;
alter table mitra_locations enable row level security;
alter table sos_events enable row level security;
alter table wallet_tx enable row level security;

create or replace function is_mitra() returns boolean language sql stable security definer as $$
  select exists(select 1 from profiles where id = auth.uid() and role = 'mitra');
$$;

create policy "profil sendiri" on profiles for select using (id = auth.uid());
create policy "ubah profil sendiri" on profiles for update using (id = auth.uid());

create policy "lihat order" on orders for select using (
  (status = 'pending' and is_mitra()) or mitra_id = auth.uid() or customer_id = auth.uid());
create policy "mitra ambil/ubah order" on orders for update
  using ((mitra_id is null and status = 'pending' and is_mitra()) or mitra_id = auth.uid())
  with check (mitra_id = auth.uid());

create policy "chat baca" on messages for select using (exists (
  select 1 from orders o where o.id = order_id and (o.mitra_id = auth.uid() or o.customer_id = auth.uid())));
create policy "chat kirim" on messages for insert with check (sender_id = auth.uid() and exists (
  select 1 from orders o where o.id = order_id and (o.mitra_id = auth.uid() or o.customer_id = auth.uid())));

create policy "rating mitra" on ratings for select using (mitra_id = auth.uid());
create policy "lokasi mitra" on mitra_locations for all
  using (mitra_id = auth.uid()) with check (mitra_id = auth.uid());
create policy "lokasi dilihat warga" on mitra_locations for select using (exists (
  select 1 from orders o where o.id = order_id and o.customer_id = auth.uid()));
create policy "sos kirim" on sos_events for insert with check (mitra_id = auth.uid());
create policy "dompet sendiri" on wallet_tx for select using (mitra_id = auth.uid());

-- Saldo dompet otomatis bertambah saat order selesai
create or replace function credit_wallet() returns trigger language plpgsql security definer as $$
begin
  if new.status = 'done' and old.status <> 'done' and new.mitra_id is not null then
    insert into wallet_tx(mitra_id, amount, kind, note)
    values (new.mitra_id, new.fee, 'credit', 'Order ' || upper(new.type));
  end if;
  return new;
end $$;
create trigger orders_credit after update on orders
  for each row execute function credit_wallet();

-- Realtime untuk order masuk & chat
alter publication supabase_realtime add table orders, messages;

-- Jadikan akun sebagai mitra (ganti email):
-- update profiles set role='mitra', name='Nama Mitra' where id=(select id from auth.users where email='mitra@contoh.com');
-- Order uji:
-- insert into orders(type,customer_name,customer_phone,pickup_address,drop_address,distance_km,fee,note)
-- values ('jastip','Bu Siti','081234567890','Warung Bu Tini','RT 05 RW 05',1.8,12000,'Nasi goreng 2');
