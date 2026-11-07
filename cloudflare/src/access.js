// The gate in front of the game, used only when FEATURE_REQUIRE_ACCESS is on.
//
// A visitor may play if they have joined a class (class code) or are a signed-in teacher whose
// plan is active. Page loads (index.html) re-check this against the database every time, so a
// cancelled subscription or archived class takes effect on the next visit. The game's other
// files (wasm, pck, lesson JSON) only check the signed access cookie, which keeps them fast.

import { currentUser } from "./auth.js";
import { planFor } from "./billing.js";
import { cookie, parseCookies, redirect, sign, unsign } from "./util.js";

const ACCESS_COOKIE = "li_access";
const ACCESS_HOURS = 12;

export async function grantAccess(env, data) {
  return cookie(ACCESS_COOKIE, await sign(env.SESSION_SECRET, data, ACCESS_HOURS * 3600), {
    maxAge: ACCESS_HOURS * 3600,
  });
}

// Paths that never need access: the sign-in / join pages and their APIs.
const OPEN = [/^\/join$/, /^\/teachers$/, /^\/auth\//, /^\/api\//, /^\/favicon\.ico$/, /^\/robots\.txt$/];

function isPage(request, path) {
  return path.endsWith("/") || path.endsWith(".html") || request.headers.get("sec-fetch-mode") === "navigate";
}

/**
 * Returns {response} to send instead of the game file, or {setCookie} (maybe empty) to carry on
 * and serve the file, refreshing the access cookie if one is given.
 */
export async function gate(request, env, flags, path) {
  if (!flags.requireAccess || OPEN.some((r) => r.test(path))) return {};
  // The editor has its own protection (FEATURE_PROTECT_EDITOR / its password).
  if (path === "/editor" || path === "/editor.html") return {};

  const pass = await unsign(env.SESSION_SECRET, parseCookies(request)[ACCESS_COOKIE]);

  if (!isPage(request, path)) {
    if (pass) return {};
    // No class cookie: a signed-in teacher (e.g. using the editor) may still fetch files.
    const user = await currentUser(request, env);
    if (user && (await planFor(env, flags, user)).active) return {};
    return { response: new Response("Ask your teacher for a class code.", { status: 403 }) };
  }

  // Full check for page loads.
  let ok = false;
  let renewed = null;
  if (pass?.k === "class") {
    ok = await classForClassId(env, flags, pass.c);
    if (ok) renewed = { k: "class", c: pass.c };
  }
  if (!ok) {
    const user = await currentUser(request, env);
    if (user && (await planFor(env, flags, user)).active) {
      ok = true;
      renewed = { k: "teacher", u: user.id };
    }
  }
  if (!ok) {
    const url = new URL(request.url);
    return { response: redirect(`/join?next=${encodeURIComponent(url.pathname + url.search)}`) };
  }
  return { setCookie: await grantAccess(env, renewed) };
}

export async function classForClassId(env, flags, classId) {
  const c = await env.DB.prepare(
    `SELECT u.id, u.email, u.email_trusted FROM classes c JOIN users u ON u.id = c.teacher_id WHERE c.id = ? AND c.archived = 0`,
  )
    .bind(classId)
    .first();
  return !!c && (await planFor(env, flags, c)).active;
}
