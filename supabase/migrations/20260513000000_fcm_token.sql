-- FCM 푸시 알림용 device token
alter table profiles
  add column if not exists fcm_token text;
