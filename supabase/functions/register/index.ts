import { bad, body, headers, json } from "../_shared/http.ts";
import { passwordHash, randomBase64, sha256Base64 } from "../_shared/crypto.ts";
import { rpc } from "../_shared/db.ts";

type RegisterRequest = { displayName: string; username: string; password: string; publicKey: string; deviceLabel: string };

Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response(null, { headers });
  if (request.method !== "POST") return bad("method not allowed", 405);
  try {
    const input = await body<RegisterRequest>(request);
    if (!/^[A-Za-z0-9_.-]{3,24}$/.test(input.username)) return bad("username non valido");
    if (!input.displayName.trim() || input.displayName.trim().length > 24) return bad("nome non valido");
    if (input.password.length < 12) return bad("la password deve avere almeno 12 caratteri");
    if (!input.publicKey || !input.deviceLabel.trim()) return bad("dati dispositivo mancanti");
    const salt = randomBase64(16);
    const rawToken = randomBase64(32);
    const result = await rpc<Array<{ profile_id: string; public_code: string; session_id: string }>>("matrix_register", {
      p_display_name: input.displayName.trim(), p_username: input.username.trim(), p_public_key: input.publicKey,
      p_password_salt: salt, p_password_hash: await passwordHash(input.password, salt),
      p_token_hash: await sha256Base64(rawToken), p_device_label: input.deviceLabel.trim(),
    });
    return json({ profileId: result[0].profile_id, publicCode: result[0].public_code, sessionToken: rawToken });
  } catch (error) {
    const message = error instanceof Error && error.message.includes("username already") ? "username già in uso" : "registrazione non disponibile";
    return bad(message, 409);
  }
});
