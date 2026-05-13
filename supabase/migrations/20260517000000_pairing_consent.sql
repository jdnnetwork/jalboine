-- 가족 연결 동의 흐름:
--  1) pair_links.status 에 'rejected' 추가
--  2) profiles 에 어르신의 가족 연결 동의 기록 (consent_family, consent_date)

alter table pair_links drop constraint if exists pair_links_status_check;
alter table pair_links
  add constraint pair_links_status_check
  check (status in ('pending', 'accepted', 'rejected'));

alter table profiles
  add column if not exists consent_family bool not null default false,
  add column if not exists consent_date timestamptz;
