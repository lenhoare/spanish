// Small helpers: responses, cookies, signing, random tokens.

const enc = new TextEncoder();

export function json(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", ...headers },
  });
}

export function html(body, status = 200, headers = {}) {
  return new Response(body, {
    status,
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store", ...headers },
  });
}

export function notFound() {
  return new Response("Not found", { status: 404, headers: { "content-type": "text/plain" } });
}

export function redirect(location, cookies = []) {
  const headers = new Headers({ location, "cache-control": "no-store" });
  for (const c of cookies) headers.append("set-cookie", c);
  return new Response(null, { status: 302, headers });
}

/** Only allow redirects back into this site ("/..." but not "//evil.com"). */
export function safeNext(next, fallback = "/") {
  const s = String(next || "");
  if (!s.startsWith("/") || s.startsWith("//") || s.startsWith("/\\")) return fallback;
  return s;
}

// ------------------------------------------------------------------ cookies

export function parseCookies(request) {
  const out = {};
  const header = request.headers.get("cookie") || "";
  for (const part of header.split(";")) {
    const i = part.indexOf("=");
    if (i < 0) continue;
    const k = part.slice(0, i).trim();
    if (k) out[k] = decodeURIComponent(part.slice(i + 1).trim());
  }
  return out;
}

export function cookie(name, value, { maxAge, path = "/", httpOnly = true } = {}) {
  let c = `${name}=${encodeURIComponent(value)}; Path=${path}; Secure; SameSite=Lax`;
  if (httpOnly) c += "; HttpOnly";
  if (maxAge !== undefined) c += `; Max-Age=${Math.max(0, Math.floor(maxAge))}`;
  return c;
}

export function clearCookie(name, path = "/") {
  return cookie(name, "", { maxAge: 0, path });
}

// ------------------------------------------------------------------ encoding / crypto

export function b64url(bytes) {
  let s = "";
  for (const b of new Uint8Array(bytes)) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function b64urlDecode(str) {
  const s = str.replace(/-/g, "+").replace(/_/g, "/");
  const bin = atob(s + "===".slice((s.length + 3) % 4));
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

export function randomToken(bytes = 32) {
  return b64url(crypto.getRandomValues(new Uint8Array(bytes)));
}

export async function sha256(text) {
  return b64url(await crypto.subtle.digest("SHA-256", enc.encode(text)));
}

async function hmacKey(secret) {
  return crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
}

export async function hmacHex(secret, message) {
  const sig = await crypto.subtle.sign("HMAC", await hmacKey(secret), enc.encode(message));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function timingSafeEqual(a, b) {
  const x = enc.encode(String(a));
  const y = enc.encode(String(b));
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

/** A tamper-proof value: base64url(JSON) + "." + HMAC. Includes an expiry (seconds). */
export async function sign(secret, data, ttlSeconds) {
  const body = b64url(enc.encode(JSON.stringify({ ...data, exp: Math.floor(Date.now() / 1000) + ttlSeconds })));
  return body + "." + (await hmacHex(secret, body));
}

export async function unsign(secret, token) {
  if (!token || typeof token !== "string") return null;
  const i = token.lastIndexOf(".");
  if (i < 1) return null;
  const body = token.slice(0, i);
  if (!timingSafeEqual(token.slice(i + 1), await hmacHex(secret, body))) return null;
  try {
    const data = JSON.parse(new TextDecoder().decode(b64urlDecode(body)));
    if (!data || typeof data.exp !== "number" || data.exp < Date.now() / 1000) return null;
    return data;
  } catch {
    return null;
  }
}

/** For POSTs from our own pages: the browser's Origin must be this site. */
export function sameOrigin(request) {
  const origin = request.headers.get("origin");
  if (!origin) return request.headers.get("sec-fetch-site") !== "cross-site";
  return origin === new URL(request.url).origin;
}

export function now() {
  return Math.floor(Date.now() / 1000);
}
