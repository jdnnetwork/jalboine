-- 잘보이네 Phase 1 재설계 마이그레이션
-- 익명 device_id 기반 피보호자 + Google/Kakao OAuth 보호자

-- profiles: 전화번호 제약 완화, age_group, device_id 추가
alter table profiles
  add column if not exists age_group text,
  add column if not exists device_id text,
  add column if not exists parent_phone text;

create index if not exists profiles_device_id_idx on profiles(device_id);

-- senior_settings: 사운드 모드, 익명 sign-in 확장
alter table senior_settings
  add column if not exists sound_mode text not null default 'sound'
    check (sound_mode in ('sound','vibrate','silent')),
  add column if not exists battery_pct int,
  add column if not exists online bool default true;

-- pair_links: senior_user_id가 null 허용 (보호자가 먼저 연결 시작 시)
alter table pair_links
  drop constraint if exists pair_links_status_check;
alter table pair_links
  add constraint pair_links_status_check
    check (status in ('pending','accepted','revoked'));

-- 게스트 익명 사용자도 자기 senior_settings 읽기/쓰기 허용 (이미 있음, 확인용)
-- 보호자 측: pair_links에서 invite_code로 senior_settings에 접근

-- 보호자가 본인 부모와 연결되면 senior 측 medications도 관리 가능해야 함
drop policy if exists "self can manage medications" on medications;
create policy "self or guardian can manage medications" on medications
  for all using (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = medications.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'accepted'
    )
  ) with check (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = medications.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'accepted'
    )
  );

-- med_logs도 보호자가 읽을 수 있도록
drop policy if exists "self can manage med logs" on med_logs;
create policy "self or guardian can manage med logs" on med_logs
  for all using (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = med_logs.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'accepted'
    )
  ) with check (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = med_logs.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'accepted'
    )
  );

-- pair_links 검색을 invite_code 기반으로 (인증 없이도 코드 입력으로 매칭 가능)
drop policy if exists "self can read or update pair links" on pair_links;
create policy "code-based or self pair links" on pair_links
  for all using (
    auth.uid() = senior_user_id
    or auth.uid() = guardian_user_id
    or guardian_user_id is null
    or senior_user_id is null
  ) with check (
    auth.uid() = senior_user_id
    or auth.uid() = guardian_user_id
    or guardian_user_id is null
    or senior_user_id is null
  );

-- realtime
alter publication supabase_realtime add table medications;
alter publication supabase_realtime add table med_logs;
alter publication supabase_realtime add table pair_links;
