-- 잘보이네 초기 스키마

create table if not exists profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('senior','guardian')),
  name text,
  phone text,
  created_at timestamptz default now()
);

create table if not exists senior_settings (
  user_id uuid primary key references profiles(user_id) on delete cascade,
  enabled_apps jsonb not null default '[]'::jsonb,
  takes_medication bool not null default false,
  emergency_contacts jsonb not null default '[]'::jsonb,
  guardian_pin_hash text,
  updated_at timestamptz default now()
);

create table if not exists medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(user_id) on delete cascade,
  times time[] not null,
  times_per_day int not null
);

create table if not exists pair_links (
  id uuid primary key default gen_random_uuid(),
  senior_user_id uuid references profiles(user_id),
  guardian_user_id uuid references profiles(user_id),
  status text not null check (status in ('pending','accepted')),
  invite_code text unique,
  created_at timestamptz default now()
);

create table if not exists med_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(user_id),
  scheduled_at timestamptz not null,
  status text check (status in ('taken','delayed','missed')),
  taken_at timestamptz
);

-- RLS
alter table profiles enable row level security;
alter table senior_settings enable row level security;
alter table medications enable row level security;
alter table pair_links enable row level security;
alter table med_logs enable row level security;

create policy "self can read profile" on profiles
  for select using (auth.uid() = user_id);
create policy "self can upsert profile" on profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "self can read settings" on senior_settings
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = senior_settings.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'accepted'
    )
  );
create policy "self or guardian can update settings" on senior_settings
  for all using (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = senior_settings.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'accepted'
    )
  ) with check (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = senior_settings.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'accepted'
    )
  );

create policy "self can manage medications" on medications
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "self can read or update pair links" on pair_links
  for all using (
    auth.uid() = senior_user_id or auth.uid() = guardian_user_id
    or guardian_user_id is null
  ) with check (
    auth.uid() = senior_user_id or auth.uid() = guardian_user_id
    or guardian_user_id is null
  );

create policy "self can manage med logs" on med_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Realtime
alter publication supabase_realtime add table senior_settings;
