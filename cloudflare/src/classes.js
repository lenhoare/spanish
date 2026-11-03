// Teachers make classes; each class has a short join code. Students type the code (or open the
// teacher's join link) and can play - no student accounts, no student personal data.
//
//   GET  /api/me                        -> who's signed in, their plan, their classes
//   POST /api/classes        {name}     -> new class
//   POST /api/classes/:id/new-code      -> replace a class's code (e.g. it was shared too widely)
//   POST /api/classes/:id/archive       -> remove a class (its code stops working)
//   POST /api/join           {code}     -> student enters a code: sets the access cookie

import { planFor } from "./billing.js";
import { json, now } from "./util.js";
import { grantAccess } from "./access.js";

const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no 0/O or 1/I confusion
const CODE_LENGTH = 6;
const MAX_CLASSES = 40;

export function normaliseCode(code) {
  return String(code || "").toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 12);
}

function newCode() {
  const bytes = crypto.getRandomValues(new Uint8Array(CODE_LENGTH));
  return [...bytes].map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join("");
}

async function uniqueCode(env) {
  for (let i = 0; i < 10; i++) {
    const code = newCode();
    if (!(await env.DB.prepare("SELECT 1 FROM classes WHERE join_code = ?").bind(code).first())) return code;
  }
  throw new Error("Could not make a unique class code");
}

/** The class for a code, if it exists and its teacher's plan is active. */
export async function classForCode(env, flags, code) {
  const c = await env.DB.prepare(
    `SELECT c.*, u.id AS u_id, u.email AS u_email FROM classes c JOIN users u ON u.id = c.teacher_id
     WHERE c.join_code = ? AND c.archived = 0`,
  )
    .bind(normaliseCode(code))
    .first();
  if (!c) return null;
  const plan = await planFor(env, flags, { id: c.u_id, email: c.u_email });
  return plan.active ? c : null;
}

export async function handleClasses(request, env, flags, path, user) {
  if (path === "/api/me" && request.method === "GET") {
    if (!user) return json({ signedIn: false, features: publicFeatures(flags) });
    const classes = await env.DB.prepare(
      "SELECT id, name, join_code, created_at FROM classes WHERE teacher_id = ? AND archived = 0 ORDER BY created_at",
    )
      .bind(user.id)
      .all();
    return json({
      signedIn: true,
      user: { email: user.email, name: user.name },
      plan: await planFor(env, flags, user),
      classes: classes.results,
      features: publicFeatures(flags),
    });
  }

  if (path === "/api/join" && request.method === "POST") {
    const body = await request.json().catch(() => ({}));
    const c = await classForCode(env, flags, body.code);
    if (!c) return json({ ok: false, error: "That code didn't work. Check it with your teacher." }, 404);
    return json({ ok: true, className: c.name }, 200, { "set-cookie": await grantAccess(env, { k: "class", c: c.id }) });
  }

  if (request.method !== "POST" || !path.startsWith("/api/classes")) return null;
  if (!user) return json({ error: "Please sign in first." }, 401);
  const plan = await planFor(env, flags, user);

  if (path === "/api/classes") {
    if (!plan.active) return json({ error: "Classes need an active subscription." }, 402);
    const body = await request.json().catch(() => ({}));
    const name = String(body.name || "").trim().slice(0, 60) || "My class";
    const count = await env.DB.prepare("SELECT COUNT(*) AS n FROM classes WHERE teacher_id = ? AND archived = 0")
      .bind(user.id)
      .first();
    if (count.n >= MAX_CLASSES) return json({ error: `You can have up to ${MAX_CLASSES} classes.` }, 400);
    const row = { id: crypto.randomUUID(), name, join_code: await uniqueCode(env), created_at: now() };
    await env.DB.prepare("INSERT INTO classes (id, teacher_id, name, join_code, created_at) VALUES (?, ?, ?, ?, ?)")
      .bind(row.id, user.id, row.name, row.join_code, row.created_at)
      .run();
    return json(row, 201);
  }

  const m = path.match(/^\/api\/classes\/([0-9a-f-]{36})\/(new-code|archive)$/);
  if (!m) return null;
  const owned = await env.DB.prepare("SELECT id FROM classes WHERE id = ? AND teacher_id = ? AND archived = 0")
    .bind(m[1], user.id)
    .first();
  if (!owned) return json({ error: "Class not found." }, 404);
  if (m[2] === "archive") {
    await env.DB.prepare("UPDATE classes SET archived = 1 WHERE id = ?").bind(m[1]).run();
    return json({ ok: true });
  }
  const code = await uniqueCode(env);
  await env.DB.prepare("UPDATE classes SET join_code = ? WHERE id = ?").bind(code, m[1]).run();
  return json({ ok: true, join_code: code });
}

export function publicFeatures(flags) {
  return {
    auth: flags.auth,
    payments: flags.payments,
    requireAccess: flags.requireAccess,
    protectEditor: flags.protectEditor,
  };
}
