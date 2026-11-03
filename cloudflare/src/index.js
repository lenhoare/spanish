// Lesson Island on Cloudflare: serves the Godot web export, plus optional teacher accounts,
// Stripe subscriptions and class-code access. See cloudflare/README.md, and flags.js for the
// switches. With every switch off this is a plain static website.

import { gate, grantAccess } from "./access.js";
import { currentUser, emailIn, handleAuth } from "./auth.js";
import { handleBilling } from "./billing.js";
import { classForCode, handleClasses, publicFeatures } from "./classes.js";
import { features } from "./flags.js";
import { html, json, notFound, redirect, safeNext, sameOrigin } from "./util.js";
import teachersPage from "./pages/teachers.html";
import joinPage from "./pages/join.html";

export default {
  async fetch(request, env) {
    try {
      return await route(request, env);
    } catch (err) {
      console.error("[worker]", err?.stack || err);
      return json({ error: "Something went wrong. Please try again." }, 500);
    }
  },
};

async function route(request, env) {
  const url = new URL(request.url);
  const path = url.pathname;
  const flags = features(env);

  // www.mscleary.com -> mscleary.com (one address, so sign-in cookies always match).
  if (url.hostname.startsWith("www.")) {
    url.hostname = url.hostname.slice(4);
    return Response.redirect(url.toString(), 301);
  }

  if (path === "/api/features") return json(publicFeatures(flags));

  // Proves to Microsoft that this domain belongs to our app ("publisher domain" in Entra).
  if (path === "/.well-known/microsoft-identity-association.json" && env.MICROSOFT_CLIENT_ID) {
    return json({ associatedApplications: [{ applicationId: env.MICROSOFT_CLIENT_ID }] });
  }

  const isApp = path === "/teachers" || path === "/join" || path.startsWith("/auth/") || path.startsWith("/api/");
  if (isApp) {
    // Everything account-related simply doesn't exist while sign-in is off.
    if (!flags.auth) return notFound();
    if (request.method === "POST" && path !== "/api/billing/webhook" && !sameOrigin(request)) {
      return json({ error: "Cross-site request refused." }, 403);
    }
    return (await appRoute(request, env, flags, url, path)) || notFound();
  }

  // Cloudflare serves editor.html at /editor as well, so guard both.
  if (flags.protectEditor && (path === "/editor" || path === "/editor.html")) {
    const user = await currentUser(request, env);
    if (!user) return redirect(`/teachers?next=${encodeURIComponent("/editor")}`);
    if (!emailIn(user, env.ADMIN_EMAILS)) {
      return html("<p style='font-family:sans-serif'>This page is for the site's admins.</p>", 403);
    }
  }

  const g = await gate(request, env, flags, path);
  if (g.response) return g.response;
  const res = await serveFile(request, env, path);
  if (!g.setCookie) return res;
  const out = new Response(res.body, res);
  out.headers.append("set-cookie", g.setCookie);
  return out;
}

async function appRoute(request, env, flags, url, path) {
  if (path.startsWith("/auth/")) return handleAuth(request, env, flags, path);

  if (path === "/teachers") return html(teachersPage);

  if (path === "/join") {
    const next = safeNext(url.searchParams.get("next"), "/");
    // A teacher's join link (/join?code=ABC123) lets students straight in.
    const code = url.searchParams.get("code");
    if (code) {
      const c = await classForCode(env, flags, code);
      if (c) return redirect(next, [await grantAccess(env, { k: "class", c: c.id })]);
    }
    return html(joinPage);
  }

  const user = await currentUser(request, env);
  if (path.startsWith("/api/billing/")) {
    if (!flags.payments || request.method !== "POST") return null;
    return handleBilling(request, env, path, user);
  }
  return handleClasses(request, env, flags, path, user);
}

// ------------------------------------------------------------------ game files

const TYPES = {
  wasm: "application/wasm",
  pck: "application/octet-stream",
  js: "text/javascript; charset=utf-8",
  json: "application/json; charset=utf-8",
  html: "text/html; charset=utf-8",
  png: "image/png",
  ogg: "audio/ogg",
};

async function serveFile(request, env, path) {
  const res = await env.ASSETS.fetch(request);
  if (res.status !== 404 || !env.LARGE_FILES || !["GET", "HEAD"].includes(request.method)) return res;

  // Files over Cloudflare's 25 MiB asset limit (usually Godot's index.wasm, maybe index.pck)
  // live in R2 instead - tools/prepare_site.mjs moves them and `npm run upload-large` uploads them.
  const key = decodeURIComponent(path.replace(/^\/+/, ""));
  const obj = await env.LARGE_FILES.get(key, { onlyIf: request.headers });
  if (!obj) return res;
  const headers = new Headers();
  obj.writeHttpMetadata(headers);
  headers.set("etag", obj.httpEtag);
  headers.set("content-type", TYPES[key.split(".").pop()] || headers.get("content-type") || "application/octet-stream");
  // Same file names after every re-export, so always revalidate (cheap 304 when unchanged).
  headers.set("cache-control", "public, max-age=0, must-revalidate");
  if (!("body" in obj)) return new Response(null, { status: 304, headers });
  return new Response(request.method === "HEAD" ? null : obj.body, { headers });
}
