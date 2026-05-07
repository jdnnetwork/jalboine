-- 보호자 대시보드 Phase 1
-- profiles.family_dismissed: 피보호자가 가족 연결 거절 시 true
-- senior_settings.guardian_name / guardian_phone: 보호자가 등록한 가족 연락처 (긴급 전화 화면 초록 카드)

alter table public.profiles
  add column if not exists family_dismissed boolean not null default false;

alter table public.senior_settings
  add column if not exists guardian_name text,
  add column if not exists guardian_phone text;
