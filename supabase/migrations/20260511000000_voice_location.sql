-- 자녀 음성 강제 울리기 + 실시간 위치 추적

alter table senior_settings
  add column if not exists emergency_voice_url text,
  add column if not exists emergency_sound_at timestamptz,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists location_updated_at timestamptz;

-- 보호자 녹음 저장용 storage bucket
insert into storage.buckets (id, name, public)
values ('emergency-voice', 'emergency-voice', true)
on conflict (id) do update set public = true;

drop policy if exists "auth can write own emergency voice" on storage.objects;
create policy "auth can write own emergency voice" on storage.objects
  for insert with check (
    bucket_id = 'emergency-voice'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "auth can update own emergency voice" on storage.objects;
create policy "auth can update own emergency voice" on storage.objects
  for update using (
    bucket_id = 'emergency-voice'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "public read emergency voice" on storage.objects;
create policy "public read emergency voice" on storage.objects
  for select using (bucket_id = 'emergency-voice');
