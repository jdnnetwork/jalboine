-- 안심 기능 (모르는번호/위치/미사용/배터리/긴급소리) + 통화 감지 알림

alter table senior_settings
  add column if not exists unknown_call_detection boolean not null default false,
  add column if not exists location_tracking boolean not null default false,
  add column if not exists inactivity_alert boolean not null default false,
  add column if not exists battery_alert boolean not null default false,
  add column if not exists emergency_sound boolean not null default false;

create table if not exists call_alerts (
  id uuid primary key default gen_random_uuid(),
  senior_id uuid not null references profiles(user_id) on delete cascade,
  phone_number text not null,
  call_duration integer,
  alert_level text not null check (alert_level in ('urgent','normal','no_response')),
  dismissed boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists call_alerts_senior_idx
  on call_alerts(senior_id, dismissed, created_at desc);

alter table call_alerts enable row level security;

create policy "senior or paired guardian can read call_alerts" on call_alerts
  for select using (
    auth.uid() = senior_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = call_alerts.senior_id
        and p.guardian_user_id = auth.uid()
        and p.status = 'accepted'
    )
  );

create policy "senior can insert own call_alerts" on call_alerts
  for insert with check (auth.uid() = senior_id);

create policy "senior or paired guardian can update call_alerts" on call_alerts
  for update using (
    auth.uid() = senior_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = call_alerts.senior_id
        and p.guardian_user_id = auth.uid()
        and p.status = 'accepted'
    )
  ) with check (
    auth.uid() = senior_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = call_alerts.senior_id
        and p.guardian_user_id = auth.uid()
        and p.status = 'accepted'
    )
  );

alter publication supabase_realtime add table call_alerts;
