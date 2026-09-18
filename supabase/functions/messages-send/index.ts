import { bad, body, headers, json } from "../_shared/http.ts";
import { requireSession, rest } from "../_shared/db.ts";

type SendInput = { recipientCode: string; ciphertext: string; encryptionHeader: string; mediaCiphertext?: string; expiresAt: string };

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const session = await requireSession(request);
    const input = await body<SendInput>(request);
    if (!input.ciphertext || !input.encryptionHeader || Number.isNaN(Date.parse(input.expiresAt))) return bad("busta cifrata non valida");
    const code = /^E([1-9]\d{0,9})$/i.exec(input.recipientCode.trim());
    if (!code) return bad("codice Matrix non valido");
    const recipientResponse = await rest(`profiles?select=id,is_founder,disabled_at&sequence_no=eq.${code[1]}&limit=1`);
    const [recipient] = await recipientResponse.json() as Array<{ id: string; is_founder: boolean; disabled_at: string | null }>;
    if (!recipient || recipient.disabled_at) return bad("destinatario non trovato", 404);
    if (recipient.is_founder && !session.is_founder) return bad("questo account non riceve messaggi", 403);
    await rest("envelopes", { method: "POST", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ sender_id: session.profile_id, recipient_id: recipient.id, ciphertext: input.ciphertext, encryption_header: input.encryptionHeader, media_ciphertext: input.mediaCiphertext ?? null, expires_at: input.expiresAt }) });
    return json({ ok: true });
  } catch { return bad("invio non disponibile", 503); }
});
