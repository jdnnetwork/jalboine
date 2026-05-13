-- pair_links: 보호자 별명 (어르신 화면에서 보여줄 이름)
alter table pair_links
  add column if not exists guardian_nickname text;
