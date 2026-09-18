import { bad, body, headers, json } from "../_shared/http.ts";
import { requireSession, rest } from "../_shared/db.ts";

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const session = await requireSession(request);
    const { after } = await body<{ after?: string }>(request);
    const afterFilter = after && !Number.isNaN(Date.parse(after)) ? `&created_at=gt.${encodeURIComponent(after)}` : "";
    const response = await rest(`envelopes?select=id,sender_id,ciphertext,encryption_header,media_ciphertext,created_at,expires_at&recipient_id=eq.${session.profile_id}&expires_at=gt.${encodeURIComponent(new Date().toISOString())}${afterFilter}&order=created_at.asc&limit=100`);
    return json({ envelopes: await response.json() });
  } catch { return bad("unauthorized", 401); }
});
