// 잘보이네 FCM v1 푸시 발송 Edge Function.
//
// 호출 방식:
//   POST /functions/v1/send-push
//   Authorization: Bearer <user JWT or anon key>
//   body: { user_id: string, title: string, body: string, data?: Record<string,string> }
//
// 환경변수: FIREBASE_SERVICE_ACCOUNT — Firebase 서비스 계정 JSON 전체 문자열.
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat firebase-sa.json)"
//
// 동작:
//   1) profiles 테이블에서 target user_id의 fcm_token 조회 (service role)
//   2) FCM v1 access token 발급 (서비스 계정 JWT → OAuth2)
//   3) FCM v1 send API 호출

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SA = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");
const PROJECT_ID = SA.project_id as string | undefined;

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

let cachedToken: string | null = null;
let cachedExpiry = 0;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!PROJECT_ID) {
      return json({ error: "FIREBASE_SERVICE_ACCOUNT not configured" }, 500);
    }

    const { user_id, title, body, data } = await req.json();
    if (!user_id || !title || !body) {
      return json({ error: "user_id, title, body required" }, 400);
    }

    const supa = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: row, error } = await supa
      .from("profiles")
      .select("fcm_token")
      .eq("user_id", user_id)
      .maybeSingle();

    if (error) return json({ error: error.message }, 500);
    const token = row?.fcm_token as string | undefined;
    if (!token) return json({ skipped: "no fcm_token" }, 200);

    const accessToken = await getAccessToken();
    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: data ?? {},
            android: {
              priority: "HIGH",
              notification: { channel_id: "jalboine_push" },
            },
          },
        }),
      },
    );

    const fcmText = await fcmRes.text();
    if (!fcmRes.ok) {
      return json({ error: "fcm failed", status: fcmRes.status, body: fcmText }, 502);
    }
    return json({ ok: true, fcm: fcmText }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(payload: unknown, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function getAccessToken(): Promise<string> {
  if (cachedToken && Date.now() < cachedExpiry) return cachedToken;

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: SA.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const enc = new TextEncoder();
  const b64 = (s: string) =>
    btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const headerB64 = b64(JSON.stringify(header));
  const payloadB64 = b64(JSON.stringify(payload));
  const signingInput = `${headerB64}.${payloadB64}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBuf(SA.private_key as string),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    enc.encode(signingInput),
  );
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  const jwt = `${signingInput}.${sigB64}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const t = await tokenRes.json();
  if (!t.access_token) {
    throw new Error(`oauth failed: ${JSON.stringify(t)}`);
  }
  cachedToken = t.access_token as string;
  cachedExpiry = Date.now() + ((t.expires_in as number) - 60) * 1000;
  return cachedToken;
}

function pemToBuf(pem: string): ArrayBuffer {
  const b64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}
