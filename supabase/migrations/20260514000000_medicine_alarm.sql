-- profiles: medicine_alarm — 약 알림 사용 여부 (사용자 동의)
alter table profiles
  add column if not exists medicine_alarm bool not null default false;
