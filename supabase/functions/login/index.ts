import { bad, body, headers, json } from "../_shared/http.ts";
import { fixedTimeEquals, passwordHash, randomBase64, sha256Base64 } from "../_shared/crypto.ts";
import { rest } from "../_shared/db.ts";

type LoginRequest = { username: string; password: string; deviceLabel: string };

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const input = await body<LoginRequest>(request);
    const response = await rest(`profiles?select=id,sequence_no,username,display_name,is_founder,password_salt,password_hash,disabled_at&username=eq.${encodeURIComponent(input.username)}&limit=1`);
    const profiles = await response.json() as Array<{ id: string; sequence_no: number; display_name: string; is_founder: boolean; password_salt: string; password_hash: string; disabled_at: string | null }>;
    const profile = profiles[0];
    if (!profile || profile.disabled_at || !fixedTimeEquals(await passwordHash(input.password, profile.password_salt), profile.password_hash)) return bad("credenziali non valide", 401);
    const token = randomBase64(32);
    await rest("device_sessions", { method: "POST", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ profile_id: profile.id, token_hash: await sha256Base64(token), device_label: input.deviceLabel, expires_at: new Date(Date.now() + 30 * 86400000).toISOString() }) });
    await rest(`profiles?id=eq.${profile.id}`, { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ status: "online", last_seen_at: new Date().toISOString() }) });
    return json({ profileId: profile.id, publicCode: `E${profile.sequence_no}`, displayName: profile.display_name, isFounder: profile.is_founder, sessionToken: token });
  } catch { return bad("accesso non disponibile", 503); }
});
