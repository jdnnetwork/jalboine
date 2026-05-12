-- 온보딩 완료 플래그 + 런처 설정 결과
alter table profiles
  add column if not exists onboarding_complete bool not null default false,
  add column if not exists launcher_set bool not null default false;
