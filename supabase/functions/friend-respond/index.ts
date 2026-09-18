import { bad, body, headers, json } from "../_shared/http.ts";
import { requireSession, rest } from "../_shared/db.ts";

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const session = await requireSession(request);
    const { requestId, accept } = await body<{ requestId: string; accept: boolean }>(request);
    const response = await rest(`friend_requests?id=eq.${encodeURIComponent(requestId)}&recipient_id=eq.${session.profile_id}&state=eq.pending`, { method: "PATCH", headers: { Prefer: "return=representation" }, body: JSON.stringify({ state: accept ? "accepted" : "rejected" }) });
    const updated = await response.json() as unknown[];
    if (updated.length !== 1) return bad("richiesta non trovata", 404);
    return json({ ok: true });
  } catch { return bad("unauthorized", 401); }
});
