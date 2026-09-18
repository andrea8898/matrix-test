import { bad, headers, json } from "../_shared/http.ts";
import { requireSession, rest } from "../_shared/db.ts";

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const session = await requireSession(request);
    const now = new Date().toISOString();
    await rest(`profiles?id=eq.${session.profile_id}`, { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ status: "online", last_seen_at: now }) });
    return json({ ok: true });
  } catch { return bad("unauthorized", 401); }
});
