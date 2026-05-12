-- medications.user_id 에 unique 제약 추가.
-- upsert(onConflict='user_id') 가 동작하도록 + 중복 행 누적 방지.
--
-- 사전 정리: 동일 user_id 의 중복 행은 id 가 큰(최신) 행만 남기고 삭제.
delete from medications a
using medications b
where a.user_id = b.user_id
  and a.id < b.id;

alter table medications
  add constraint medications_user_id_key unique (user_id);
