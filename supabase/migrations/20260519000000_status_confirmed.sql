-- pair_links.status: 'accepted' → 'confirmed' 으로 통일
-- 코드 / RLS 정책 양쪽이 'confirmed' 를 사용하도록 변경.

-- 1) CHECK 제약 먼저 제거 (없애야 'confirmed' 로 UPDATE 가능)
alter table pair_links drop constraint if exists pair_links_status_check;

-- 2) 기존 데이터 마이그레이션
update pair_links set status = 'confirmed' where status = 'accepted';

-- 3) 새 CHECK 제약 추가
alter table pair_links
  add constraint pair_links_status_check
  check (status in ('pending', 'confirmed', 'rejected'));

-- 3) RLS 정책 재생성 — 'accepted' 참조하던 정책을 'confirmed' 로

-- senior_settings
drop policy if exists "self can read settings" on senior_settings;
create policy "self can read settings" on senior_settings
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = senior_settings.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'confirmed'
    )
  );

drop policy if exists "self or guardian can update settings" on senior_settings;
create policy "self or guardian can update settings" on senior_settings
  for all using (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = senior_settings.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'confirmed'
    )
  ) with check (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = senior_settings.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'confirmed'
    )
  );

-- medications
drop policy if exists "self or guardian can manage medications" on medications;
create policy "self or guardian can manage medications" on medications
  for all using (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = medications.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'confirmed'
    )
  ) with check (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = medications.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'confirmed'
    )
  );

-- med_logs
drop policy if exists "self or guardian can manage med logs" on med_logs;
create policy "self or guardian can manage med logs" on med_logs
  for all using (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = med_logs.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'confirmed'
    )
  ) with check (
    auth.uid() = user_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = med_logs.user_id
      and p.guardian_user_id = auth.uid()
      and p.status = 'confirmed'
    )
  );

-- messages (insert if paired)
drop policy if exists "sender can insert if paired" on messages;
create policy "sender can insert if paired" on messages
  for insert with check (
    auth.uid() = sender_id
    and exists (
      select 1 from pair_links p
      where p.status = 'confirmed'
        and (
          (p.senior_user_id = sender_id and p.guardian_user_id = receiver_id)
          or (p.guardian_user_id = sender_id and p.senior_user_id = receiver_id)
        )
    )
  );

-- call_alerts (read)
drop policy if exists "senior or paired guardian can read call_alerts" on call_alerts;
create policy "senior or paired guardian can read call_alerts" on call_alerts
  for select using (
    auth.uid() = senior_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = call_alerts.senior_id
        and p.guardian_user_id = auth.uid()
        and p.status = 'confirmed'
    )
  );

-- call_alerts (update)
drop policy if exists "senior or paired guardian can update call_alerts" on call_alerts;
create policy "senior or paired guardian can update call_alerts" on call_alerts
  for update using (
    auth.uid() = senior_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = call_alerts.senior_id
        and p.guardian_user_id = auth.uid()
        and p.status = 'confirmed'
    )
  ) with check (
    auth.uid() = senior_id
    or exists (
      select 1 from pair_links p
      where p.senior_user_id = call_alerts.senior_id
        and p.guardian_user_id = auth.uid()
        and p.status = 'confirmed'
    )
  );
