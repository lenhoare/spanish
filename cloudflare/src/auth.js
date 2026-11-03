// Teacher sign-in. Google first; each provider is one entry in PROVIDERS, so Microsoft
// (common in UK schools) can be added later with the same flow.
//
//   GET  /auth/google            -> Google's sign-in page
//   GET  /auth/google/callback   -> back from Google: make the account + session, then go to ?next
//   POST /auth/logout

import {
  b64url, b64urlDecode, clearCookie, cookie, json, now, parseCookies, randomToken, redirect, safeNext, sha256, sign, unsign,
} from "./util.js";

const SESSION_COOKIE = "li_session";
const OAUTH_COOKIE = "li_oauth";
const SESSION_DAYS = 30;

const PROVIDERS = {
  google: {
    authorize: "https://accounts.google.com/o/oauth2/v2/auth",
    token: "https://oauth2.googleapis.com/token",
    issuers: ["https://accounts.google.com", "accounts.google.com"],
    scope: "openid email profile",
    clientId: (env) => env.GOOGLE_CLIENT_ID,
    clientSecret: (env) => env.GOOGLE_CLIENT_SECRET,
  },
};

function callbackUrl(env, request, provider) {
  const base = (env.PUBLIC_URL || new URL(request.url).origin).replace(/\/+$/, "");
  return `${base}/auth/${provider}/callback`;
}

export async function handleAuth(request, env, path) {
  const m = path.match(/^\/auth\/([a-z]+)(\/callback)?$/);
  if (path === "/auth/logout") {
    if (request.method !== "POST") return new Response("Use POST", { status: 405 });
    return logout(request, env);
  }
  if (!m || !PROVIDERS[m[1]] || request.method !== "GET") return null;
  return m[2] ? callback(request, env, m[1]) : start(request, env, m[1]);
}

async function start(request, env, name) {
  const p = PROVIDERS[name];
  const url = new URL(request.url);
  const state = randomToken(16);
  const nonce = randomToken(16);
  const verifier = randomToken(32);
  const challenge = b64url(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier)));
  const next = safeNext(url.searchParams.get("next"), "/teachers");

  const auth = new URL(p.authorize);
  auth.search = new URLSearchParams({
    client_id: p.clientId(env),
    redirect_uri: callbackUrl(env, request, name),
    response_type: "code",
    scope: p.scope,
    state,
    nonce,
    code_challenge: challenge,
    code_challenge_method: "S256",
    prompt: "select_account",
  }).toString();

  const pending = await sign(env.SESSION_SECRET, { state, nonce, verifier, next, p: name }, 600);
  return redirect(auth.toString(), [cookie(OAUTH_COOKIE, pending, { maxAge: 600, path: "/auth" })]);
}

async function callback(request, env, name) {
  const p = PROVIDERS[name];
  const url = new URL(request.url);
  const pending = await unsign(env.SESSION_SECRET, parseCookies(request)[OAUTH_COOKIE]);
  const fail = (why) => {
    console.warn("[auth] sign-in failed:", why);
    return redirect("/teachers?signin=failed", [clearCookie(OAUTH_COOKIE, "/auth")]);
  };

  if (url.searchParams.get("error")) return fail(url.searchParams.get("error"));
  if (!pending || pending.p !== name) return fail("no pending sign-in (cookie missing or expired)");
  if (url.searchParams.get("state") !== pending.state) return fail("state mismatch");

  const res = await fetch(p.token, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      code: url.searchParams.get("code") || "",
      client_id: p.clientId(env),
      client_secret: p.clientSecret(env),
      redirect_uri: callbackUrl(env, request, name),
      grant_type: "authorization_code",
      code_verifier: pending.verifier,
    }),
  });
  if (!res.ok) return fail(`token exchange ${res.status}: ${await res.text()}`);
  const tokens = await res.json();

  // The ID token came straight from Google over HTTPS in exchange for our client secret,
  // so its signature doesn't need re-checking here (Google's guidance) - but the claims do.
  let claims;
  try {
    claims = JSON.parse(new TextDecoder().decode(b64urlDecode(tokens.id_token.split(".")[1])));
  } catch {
    return fail("unreadable id_token");
  }
  if (!p.issuers.includes(claims.iss)) return fail("wrong issuer");
  if (claims.aud !== p.clientId(env)) return fail("wrong audience");
  if (claims.exp < now()) return fail("expired id_token");
  if (claims.nonce !== pending.nonce) return fail("nonce mismatch");
  if (!claims.email || claims.email_verified === false) return fail("email not verified");

  const user = await upsertUser(env, name, claims);
  const token = randomToken(32);
  const t = now();
  await env.DB.prepare("INSERT INTO sessions (id, user_id, created_at, expires_at) VALUES (?, ?, ?, ?)")
    .bind(await sha256(token), user.id, t, t + SESSION_DAYS * 86400)
    .run();
  // Tidy up old sessions now and then.
  await env.DB.prepare("DELETE FROM sessions WHERE expires_at < ?").bind(t).run();

  return redirect(pending.next, [
    clearCookie(OAUTH_COOKIE, "/auth"),
    cookie(SESSION_COOKIE, token, { maxAge: SESSION_DAYS * 86400 }),
  ]);
}

async function upsertUser(env, provider, claims) {
  const t = now();
  const existing = await env.DB.prepare("SELECT * FROM users WHERE provider = ? AND provider_sub = ?")
    .bind(provider, claims.sub)
    .first();
  if (existing) {
    await env.DB.prepare("UPDATE users SET email = ?, name = ?, last_login_at = ? WHERE id = ?")
      .bind(claims.email.toLowerCase(), claims.name || "", t, existing.id)
      .run();
    return { ...existing, email: claims.email.toLowerCase(), name: claims.name || "" };
  }
  const user = {
    id: crypto.randomUUID(),
    provider,
    provider_sub: claims.sub,
    email: claims.email.toLowerCase(),
    name: claims.name || "",
  };
  await env.DB.prepare(
    "INSERT INTO users (id, provider, provider_sub, email, name, created_at, last_login_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
  )
    .bind(user.id, provider, user.provider_sub, user.email, user.name, t, t)
    .run();
  return user;
}

/** The signed-in teacher for this request, or null. */
export async function currentUser(request, env) {
  const token = parseCookies(request)[SESSION_COOKIE];
  if (!token) return null;
  return env.DB.prepare(
    `SELECT u.* FROM sessions s JOIN users u ON u.id = s.user_id WHERE s.id = ? AND s.expires_at > ?`,
  )
    .bind(await sha256(token), now())
    .first();
}

async function logout(request, env) {
  const token = parseCookies(request)[SESSION_COOKIE];
  if (token) await env.DB.prepare("DELETE FROM sessions WHERE id = ?").bind(await sha256(token)).run();
  return json({ ok: true }, 200, { "set-cookie": clearCookie(SESSION_COOKIE) });
}
