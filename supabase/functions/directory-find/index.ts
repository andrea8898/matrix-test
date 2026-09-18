import { bad, body, headers, json } from "../_shared/http.ts";
import { requireSession, rest } from "../_shared/db.ts";

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    await requireSession(request);
    const { publicCode } = await body<{ publicCode: string }>(request);
    const match = /^E([1-9]\d{0,9})$/i.exec(publicCode.trim());
    if (!match) return bad("codice Matrix non valido");
    const response = await rest(`directory?select=public_code,username,display_name,status&id=not.is.null&public_code=eq.E${match[1]}`);
    const profiles = await response.json();
    return json({ profile: profiles[0] ?? null });
  } catch { return bad("unauthorized", 401); }
});
