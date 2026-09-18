const url = Deno.env.get("SUPABASE_URL")!;
const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function endpoint(path: string): string { return `${url}/rest/v1/${path}`; }
function requestHeaders(extra: HeadersInit = {}): Headers {
  return new Headers({ apikey: key, Authorization: `Bearer ${key}`, "Content-Type": "application/json", ...extra });
}

export async function rest(path: string, init: RequestInit = {}): Promise<Response> {
  return fetch(endpoint(path), { ...init, headers: requestHeaders(init.headers) });
}

export async function rpc<T>(functionName: string, args: unknown): Promise<T> {
  const response = await rest(`rpc/${functionName}`, { method: "POST", body: JSON.stringify(args) });
  if (!response.ok) throw new Error(await response.text());
  return await response.json() as T;
}

export async function activeSession(token: string): Promise<{ profile_id: string; is_founder: boolean }> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  const tokenHash = btoa(String.fromCharCode(...new Uint8Array(digest)));
  const response = await rest(`device_sessions?select=profile_id,profiles!inner(is_founder,disabled_at)&token_hash=eq.${encodeURIComponent(tokenHash)}&revoked_at=is.null&expires_at=gt.${encodeURIComponent(new Date().toISOString())}`);
  if (!response.ok) throw new Error("session lookup failed");
  const records = await response.json() as Array<{ profile_id: string; profiles: { is_founder: boolean; disabled_at: string | null } }>;
  if (records.length !== 1 || records[0].profiles.disabled_at) throw new Error("unauthorized");
  return { profile_id: records[0].profile_id, is_founder: records[0].profiles.is_founder };
}

export async function requireSession(request: Request) {
  const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) throw new Error("unauthorized");
  return activeSession(token);
}
