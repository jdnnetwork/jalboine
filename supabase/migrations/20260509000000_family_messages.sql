-- 가족 메시지: 피보호자 ↔ 보호자 1:1 채팅 (텍스트 + 이미지)
-- 무료 한도는 클라이언트가 created_at 기준 month-window count 로 체크.

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references profiles(user_id) on delete cascade,
  receiver_id uuid not null references profiles(user_id) on delete cascade,
  content text,
  image_url text,
  created_at timestamptz not null default now(),
  constraint messages_text_or_image
    check ((content is not null and length(content) > 0) or image_url is not null)
);

create index if not exists messages_pair_idx
  on messages(sender_id, receiver_id, created_at desc);
create index if not exists messages_recv_idx
  on messages(receiver_id, created_at desc);
create index if not exists messages_sender_month_idx
  on messages(sender_id, created_at);

alter table messages enable row level security;

-- 본인이 sender 거나 receiver 일 때만 읽을 수 있음
create policy "participant can read messages" on messages
  for select using (
    auth.uid() = sender_id or auth.uid() = receiver_id
  );

-- sender 가 본인이고, receiver 와 accepted pair 가 있어야 insert 허용
create policy "sender can insert if paired" on messages
  for insert with check (
    auth.uid() = sender_id
    and exists (
      select 1 from pair_links p
      where p.status = 'accepted'
        and (
          (p.senior_user_id = sender_id and p.guardian_user_id = receiver_id)
          or (p.guardian_user_id = sender_id and p.senior_user_id = receiver_id)
        )
    )
  );

-- realtime
alter publication supabase_realtime add table messages;

-- 이미지 저장용 storage bucket. 공개 읽기 (url 직접 노출), 인증된 사용자만 쓰기.
insert into storage.buckets (id, name, public)
values ('message-images', 'message-images', true)
on conflict (id) do update set public = true;

-- 인증된 사용자는 본인 폴더(=auth.uid()/...)에만 업로드 가능
drop policy if exists "auth can upload own message images" on storage.objects;
create policy "auth can upload own message images" on storage.objects
  for insert with check (
    bucket_id = 'message-images'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 공개 읽기
drop policy if exists "public read message images" on storage.objects;
create policy "public read message images" on storage.objects
  for select using (bucket_id = 'message-images');
