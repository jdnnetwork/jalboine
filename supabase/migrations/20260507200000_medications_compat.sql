-- 기존 times_per_day 컬럼 nullable 처리 (코드는 frequency를 사용하지만 호환을 위해 유지).

alter table public.medications
  alter column times_per_day drop not null;
