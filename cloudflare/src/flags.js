// Feature switches.
//
// Every optional feature is OFF unless its switch says "on" in wrangler.jsonc ("vars") or the
// Cloudflare dashboard. With everything off the Worker just serves the game as an open website:
// no sign-in, no payments, no extra pages; /teachers, /join, /auth/* and /api/* all return 404
// (except /api/features, which reports that everything is off).
//
// The switches depend on each other, so a stray "on" can never half-enable something:
//   FEATURE_AUTH             master switch - Google sign-in for teachers. Off = everything off.
//   FEATURE_PAYMENTS         Stripe subscriptions for teachers. Needs FEATURE_AUTH.
//   FEATURE_REQUIRE_ACCESS   the game needs a class code (students) or a teacher sign-in. Needs FEATURE_AUTH.
//   FEATURE_PROTECT_EDITOR   editor.html needs a Google sign-in from ADMIN_EMAILS. Needs FEATURE_AUTH.
//
// A feature that is switched on but missing a secret it needs stays OFF (and says why in the
// Worker logs), so a half-finished setup fails open - the game stays playable - rather than
// locking everyone out.

const TRUTHY = new Set(["on", "true", "1", "yes"]);

export function isOn(value) {
  return TRUTHY.has(String(value ?? "").trim().toLowerCase());
}

export function listOf(value) {
  return String(value ?? "")
    .split(/[\s,;]+/)
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
}

function missing(env, names) {
  return names.filter((n) => !env[n]);
}

const warned = new Set();
function warn(msg) {
  if (!warned.has(msg)) {
    warned.add(msg);
    console.warn("[features] " + msg);
  }
}

export function features(env) {
  const problems = [];
  const want = {
    auth: isOn(env.FEATURE_AUTH),
    payments: isOn(env.FEATURE_PAYMENTS),
    requireAccess: isOn(env.FEATURE_REQUIRE_ACCESS),
    protectEditor: isOn(env.FEATURE_PROTECT_EDITOR),
  };

  let auth = want.auth;
  if (auth) {
    const m = missing(env, ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "SESSION_SECRET", "DB"]);
    if (m.length) {
      problems.push(`FEATURE_AUTH is on but ${m.join(", ")} is not set, so sign-in stays off.`);
      auth = false;
    }
  }

  const needsAuth = (name, wanted) => {
    if (wanted && !auth) problems.push(`${name} is on but sign-in (FEATURE_AUTH) is off, so it stays off.`);
    return wanted && auth;
  };

  let payments = needsAuth("FEATURE_PAYMENTS", want.payments);
  if (payments) {
    const m = missing(env, ["STRIPE_SECRET_KEY", "STRIPE_WEBHOOK_SECRET", "STRIPE_PRICE_ID"]);
    if (m.length) {
      problems.push(`FEATURE_PAYMENTS is on but ${m.join(", ")} is not set, so payments stay off.`);
      payments = false;
    }
  }

  const requireAccess = needsAuth("FEATURE_REQUIRE_ACCESS", want.requireAccess);

  let protectEditor = needsAuth("FEATURE_PROTECT_EDITOR", want.protectEditor);
  if (protectEditor && listOf(env.ADMIN_EMAILS).length === 0) {
    problems.push("FEATURE_PROTECT_EDITOR is on but ADMIN_EMAILS is empty, so the editor stays as it is.");
    protectEditor = false;
  }

  problems.forEach(warn);
  return { auth, payments, requireAccess, protectEditor, problems };
}
