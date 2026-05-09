-- 안심 프리미엄 구독 상태
alter table profiles
  add column if not exists subscription_status text not null default 'free'
    check (subscription_status in ('free','premium')),
  add column if not exists subscription_expires_at timestamptz;
