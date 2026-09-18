import { bad, body, headers, json } from "../_shared/http.ts";
import { passwordHash, randomBase64, sha256Base64, fixedTimeEquals } from "../_shared/crypto.ts";
import { rpc } from "../_shared/db.ts";

type BootstrapRequest = { bootstrapCode: string; password: string; publicKey: string; deviceLabel: string };

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const input = await body<BootstrapRequest>(request);
    const expected = Deno.env.get("FOUNDER_BOOTSTRAP_SECRET");
    if (!expected || !fixedTimeEquals(input.bootstrapCode, expected)) return bad("unauthorized", 401);
    if (input.password.length < 12 || !input.publicKey || !input.deviceLabel.trim()) return bad("dati non validi");
    const salt = randomBase64(16), token = randomBase64(32);
    const result = await rpc<Array<{ profile_id: string; public_code: string }>>("matrix_bootstrap_founder", {
      p_display_name: "Ghost", p_username: "Black", p_public_key: input.publicKey,
      p_password_salt: salt, p_password_hash: await passwordHash(input.password, salt),
      p_token_hash: await sha256Base64(token), p_device_label: input.deviceLabel.trim(),
    });
    return json({ profileId: result[0].profile_id, publicCode: result[0].public_code, sessionToken: token });
  } catch { return bad("inizializzazione non disponibile", 409); }
});
