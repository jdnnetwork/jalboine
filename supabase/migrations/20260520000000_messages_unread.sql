-- messages: 가족 메시지 읽음 상태 + pair_link 연결 컬럼 추가
alter table messages
  add column if not exists is_read bool not null default false,
  add column if not exists pair_link_id uuid references pair_links(id) on delete cascade;

-- 받은이 + 읽지않음 빠르게 조회 (가족 카드 미읽 배지)
create index if not exists messages_receiver_unread_idx
  on messages(receiver_id, is_read)
  where is_read = false;
