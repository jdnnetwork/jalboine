-- 온보딩 음성 재생(audio_guide_mode), 홈 카드 더블탭(voice_guide_mode) 분리.

alter table public.profiles
  add column if not exists audio_guide_mode boolean not null default false,
  add column if not exists voice_guide_mode boolean not null default false;
