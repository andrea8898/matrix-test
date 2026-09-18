import { bad, headers, json } from "../_shared/http.ts";
import { requireSession, rest } from "../_shared/db.ts";

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const session = await requireSession(request);
    if (!session.is_founder) return bad("forbidden", 403);
    const [summaryResponse, usersResponse] = await Promise.all([
      rest("matrix_admin_summary?select=*"),
      rest("profiles?select=id,sequence_no,username,display_name,status,created_at,disabled_at&order=sequence_no.desc&limit=100"),
    ]);
    return json({ summary: (await summaryResponse.json())[0], accounts: await usersResponse.json() });
  } catch { return bad("unauthorized", 401); }
});
