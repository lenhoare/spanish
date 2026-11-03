// Teacher sign-in with Google or Microsoft (school Microsoft 365 / Teams accounts).
// Both use the same OpenID Connect flow (authorization code + PKCE); each provider below
// only says where its pages are and how to read and check who signed in.
//
//   GET  /auth/<provider>            -> the provider's sign-in page   (provider: google | microsoft)
//   GET  /auth/<provider>/callback   -> back from it: make the account + session, then go to ?next
//   POST /auth/logout

import { listOf } from "./flags.js";
import {
  b64url, b64urlDecode, clearCookie, cookie, json, now, parseCookies, randomToken, redirect, safeNext, sha256, sign, unsign,
} from "./util.js";

const SESSION_COOKIE = "li_session";
const OAUTH_COOKIE = "li_oauth";
const SESSION_DAYS = 30;

// Microsoft's tenant for personal (outlook.com / hotmail) accounts.
const MS_CONSUMER_TENANT = "9188040d-6c67-4c5b-b112-36a304b66dad";
const GUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const PROVIDERS = {
  google: {
    authorize: () => "https://accounts.google.com/o/oauth2/v2/auth",
    token: () => "https://oauth2.googleapis.com/token",
    clientId: (env) => env.GOOGLE_CLIENT_ID,
    clientSecret: (env) => env.GOOGLE_CLIENT_SECRET,
    /** -> {email, emailTrusted, name} or {error} */
    identity(claims) {
      if (!["https://accounts.google.com", "accounts.google.com"].includes(claims.iss)) return { error: "wrong issuer" };
      if (!claims.email || claims.email_verified !== true) return { error: "email not verified" };
      return { email: claims.email, emailTrusted: true, name: claims.name };
    },
  },

  microsoft: {
    // MICROSOFT_TENANT: "organizations" (any school/work account - the default), "common" (also
    // personal accounts), or one school's tenant id to allow only that school.
    authorize: (env) => `https://login.microsoftonline.com/${msTenant(env)}/oauth2/v2.0/authorize`,
    token: (env) => `https://login.microsoftonline.com/${msTenant(env)}/oauth2/v2.0/token`,
    clientId: (env) => env.MICROSOFT_CLIENT_ID,
    clientSecret: (env) => env.MICROSOFT_CLIENT_SECRET,
    identity(claims, env) {
      if (!claims.tid || claims.iss !== `https://login.microsoftonline.com/${claims.tid}/v2.0`) return { error: "wrong issuer" };
      const tenant = msTenant(env);
      if (GUID.test(tenant) && claims.tid.toLowerCase() !== tenant.toLowerCase()) return { error: "other organisation" };
      if (tenant === "organizations" && claims.tid === MS_CONSUMER_TENANT) return { error: "personal account" };
      const email = claims.email || claims.preferred_username;
      if (!email || !email.includes("@")) return { error: "no email address" };
      // Microsoft organisations can set any email on their accounts. Only treat the email as
      // proof of identity (for ADMIN_EMAILS / COMPLIMENTARY_EMAILS) when Microsoft says the
      // organisation owns that email domain, or the organisation is one we've listed as trusted.
      const emailTrusted = claims.xms_edov === true || claims.xms_edov === "1" ||
        listOf(env.MICROSOFT_TRUSTED_TENANTS).includes(claims.tid.toLowerCase());
      return { email, emailTrusted, name: claims.name };
    },
  },
};

function msTenant(env) {
  return String(env.MICROSOFT_TENANT || "organizations").trim();
}

function callbackUrl(env, request, provider) {
  const base = (env.PUBLIC_URL || new URL(request.url).origin).replace(/\/+$/, "");
  return `${base}/auth/${provider}/callback`;
}

export async function handleAuth(request, env, flags, path) {
  if (path === "/auth/logout") {
    if (request.method !== "POST") return new Response("Use POST", { status: 405 });
    return logout(request, env);
  }
  const m = path.match(/^\/auth\/([a-z]+)(\/callback)?$/);
  if (!m || !flags.providers.includes(m[1]) || request.method !== "GET") return null;
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

  const auth = new URL(p.authorize(env));
  auth.search = new URLSearchParams({
    client_id: p.clientId(env),
    redirect_uri: callbackUrl(env, request, name),
    response_type: "code",
    scope: "openid email profile",
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
  const fail = (why, reason = "failed") => {
    console.warn(`[auth] ${name} sign-in failed:`, why);
    return redirect(`/teachers?signin=${reason}`, [clearCookie(OAUTH_COOKIE, "/auth")]);
  };

  const error = url.searchParams.get("error");
  if (error) {
    // Typical for school Microsoft accounts whose IT team must approve new apps first.
    const desc = url.searchParams.get("error_description") || "";
    if (/AADSTS65001|AADSTS90094|consent|admin/i.test(desc + error)) return fail(`${error}: ${desc}`, "needs-admin");
    return fail(`${error}: ${desc}`, error === "access_denied" ? "cancelled" : "failed");
  }
  if (!pending || pending.p !== name) return fail("no pending sign-in (cookie missing or expired)");
  if (url.searchParams.get("state") !== pending.state) return fail("state mismatch");

  const res = await fetch(p.token(env), {
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

  // The ID token came straight from the provider over HTTPS in exchange for our client secret,
  // so its signature doesn't need re-checking (both providers' guidance) - but the claims do.
  let claims;
  try {
    claims = JSON.parse(new TextDecoder().decode(b64urlDecode(tokens.id_token.split(".")[1])));
  } catch {
    return fail("unreadable id_token");
  }
  if (claims.aud !== p.clientId(env)) return fail("wrong audience");
  if (!(claims.exp > now())) return fail("expired id_token");
  if (claims.nonce !== pending.nonce) return fail("nonce mismatch");
  if (!claims.sub) return fail("no subject");
  const who = p.identity(claims, env);
  if (who.error) return fail(who.error, who.error === "personal account" ? "personal" : "failed");

  const user = await upsertUser(env, name, claims.sub, who);
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

async function upsertUser(env, provider, sub, who) {
  const t = now();
  const email = who.email.toLowerCase();
  const name = who.name || "";
  const trusted = who.emailTrusted ? 1 : 0;
  const existing = await env.DB.prepare("SELECT * FROM users WHERE provider = ? AND provider_sub = ?")
    .bind(provider, sub)
    .first();
  if (existing) {
    await env.DB.prepare("UPDATE users SET email = ?, name = ?, email_trusted = ?, last_login_at = ? WHERE id = ?")
      .bind(email, name, trusted, t, existing.id)
      .run();
    return { ...existing, email, name, email_trusted: trusted };
  }
  const user = { id: crypto.randomUUID(), provider, provider_sub: sub, email, name, email_trusted: trusted };
  await env.DB.prepare(
    `INSERT INTO users (id, provider, provider_sub, email, name, email_trusted, created_at, last_login_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(user.id, provider, sub, email, name, trusted, t, t)
    .run();
  return user;
}

/** True if this user's email is in the given list AND we can trust that it's really theirs. */
export function emailIn(user, list) {
  return !!user && user.email_trusted === 1 && listOf(list).includes(String(user.email).toLowerCase());
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
