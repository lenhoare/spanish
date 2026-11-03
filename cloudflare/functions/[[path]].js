// Cloudflare Pages refuses any single file over 25 MiB, and Godot's index.wasm is ~38 MB.
// tools/build_cloudflare.py uploads it in parts (index.wasm.part0, .part1, ...) plus a small
// index.wasm.parts.json, and this function stitches them back together as /index.wasm.
// _routes.json makes sure this only runs for /index.wasm - every other file is plain static.

export async function onRequest({ request, env, next, waitUntil }) {
  const url = new URL(request.url);
  if (url.pathname !== "/index.wasm") return next();
  if (request.method !== "GET" && request.method !== "HEAD") {
    return new Response(null, { status: 405, headers: { Allow: "GET, HEAD" } });
  }

  const asset = (path) => env.ASSETS.fetch(new URL(path, url));
  const man = await asset("/index.wasm.parts.json");
  if (!man.ok) return new Response("index.wasm is missing from this deploy", { status: 404 });
  const { parts, size, etag } = await man.json();

  const headers = {
    "Content-Type": "application/wasm",
    "Cache-Control": "no-cache",
    ETag: `"${etag}"`,
  };
  if (request.headers.get("If-None-Match") === headers.ETag) {
    return new Response(null, { status: 304, headers });
  }
  if (request.method === "HEAD") {
    return new Response(null, { headers: { ...headers, "Content-Length": String(size) } });
  }

  const { readable, writable } = new FixedLengthStream(size);
  waitUntil((async () => {
    try {
      for (const p of parts) {
        const r = await asset("/" + p);
        if (!r.ok) throw new Error(`missing ${p} (${r.status})`);
        await r.body.pipeTo(writable, { preventClose: true });
      }
      await writable.close();
    } catch (e) {
      await writable.abort(e);
    }
  })());
  return new Response(readable, { headers });
}
