import { bad, body, headers, json } from "../_shared/http.ts";
import { requireSession, rest } from "../_shared/db.ts";

type Input = { publicCode: string; action: "disable" | "enable" | "revoke_sessions" };

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const admin = await requireSession(request);
    if (!admin.is_founder) return bad("forbidden", 403);
    const { publicCode, action } = await body<Input>(request);
    const code = /^E([1-9]\d{0,9})$/i.exec(publicCode.trim());
    if (!code || !["disable", "enable", "revoke_sessions"].includes(action)) return bad("richiesta non valida");
    const targetResponse = await rest(`profiles?select=id,is_founder&sequence_no=eq.${code[1]}&limit=1`);
    const [target] = await targetResponse.json() as Array<{ id: string; is_founder: boolean }>;
    if (!target || target.is_founder) return bad("account non disponibile", 404);
    if (action === "disable") await rest(`profiles?id=eq.${target.id}`, { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ disabled_at: new Date().toISOString(), status: "offline" }) });
    if (action === "enable") await rest(`profiles?id=eq.${target.id}`, { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ disabled_at: null }) });
    if (action === "revoke_sessions" || action === "disable") await rest(`device_sessions?profile_id=eq.${target.id}&revoked_at=is.null`, { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ revoked_at: new Date().toISOString() }) });
    return json({ ok: true });
  } catch { return bad("azione amministrativa non disponibile", 503); }
});
