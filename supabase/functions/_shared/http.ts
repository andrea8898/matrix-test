export const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers });
}

export function bad(message: string, status = 400): Response {
  return json({ error: message }, status);
}

export async function body<T>(request: Request): Promise<T> {
  try { return await request.json() as T; }
  catch { throw new Error("invalid JSON"); }
}
