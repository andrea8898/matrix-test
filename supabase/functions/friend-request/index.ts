import { bad, body, headers, json } from "../_shared/http.ts";
import { requireSession, rest } from "../_shared/db.ts";

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const session = await requireSession(request);
    const { recipientCode } = await body<{ recipientCode: string }>(request);
    const match = /^E([1-9]\d{0,9})$/i.exec(recipientCode.trim());
    if (!match) return bad("codice Matrix non valido");
    const targetResponse = await rest(`profiles?select=id,is_founder,disabled_at&sequence_no=eq.${match[1]}&limit=1`);
    const [target] = await targetResponse.json() as Array<{ id: string; is_founder: boolean; disabled_at: string | null }>;
    if (!target || target.disabled_at) return bad("utente non trovato", 404);
    // The founder may initiate requests, but no account may send requests to the founder.
    if (target.is_founder && !session.is_founder) return bad("questo account non riceve richieste", 403);
    if (target.id === session.profile_id) return bad("non puoi aggiungere te stesso");
    const insert = await rest("friend_requests", { method: "POST", headers: { Prefer: "return=minimal,resolution=merge-duplicates" }, body: JSON.stringify({ sender_id: session.profile_id, recipient_id: target.id }) });
    if (!insert.ok) return bad("richiesta già presente", 409);
    return json({ ok: true });
  } catch { return bad("unauthorized", 401); }
});
