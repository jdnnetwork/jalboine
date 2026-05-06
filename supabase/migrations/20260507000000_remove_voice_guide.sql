-- 음성 안내/더블탭 모드 제거. font_size_level / selected_apps / 약 알림 컬럼 추가.

alter table public.profiles
  add column if not exists font_size_level integer not null default 1,
  add column if not exists selected_apps text[] not null default '{}'::text[];

alter table public.medications
  add column if not exists frequency integer,
  add column if not exists alarm_enabled boolean not null default true;
