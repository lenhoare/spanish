"""Gets the web build ready for Cloudflare Pages, in cloudflare/public.

Cloudflare Pages won't take a single file over 25 MiB, and Godot's index.wasm is bigger, so it
is split into parts and cloudflare/functions/[[path]].js joins them again when a browser asks
for index.wasm. Everything else is copied as normal static files.

Usage:
    python tools/build_cloudflare.py [path/to/build/web]     (default: build/web)
then deploy (first time it asks you to log in to Cloudflare in the browser):
    cd cloudflare
    npx wrangler pages deploy
"""
import hashlib
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(ROOT, "build", "web")
OUT = os.path.join(ROOT, "cloudflare", "public")
PART = 20 * 1024 * 1024  # comfortably under Cloudflare's 25 MiB per-file limit

# Taken fresh from the project rather than whatever was last copied into build/web.
FRESH = ["config.json", "config_retos.json", "games.json"]


def main() -> None:
    if not os.path.exists(os.path.join(WEB, "index.wasm")):
        sys.exit(f"No web build found in {WEB} - export the game first (see README).")
    if os.path.exists(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)

    # The Godot export itself (skipping editor .import leftovers and things we copy fresh below).
    for name in os.listdir(WEB):
        src = os.path.join(WEB, name)
        if (not os.path.isfile(src) or name.endswith(".import") or name == "index.wasm"
                or name in FRESH or name == "editor.html"):
            continue
        shutil.copy2(src, OUT)

    # Game config, the island editor and the lesson files (JSON only).
    for name in FRESH:
        if os.path.exists(os.path.join(ROOT, name)):
            shutil.copy2(os.path.join(ROOT, name), OUT)
    shutil.copy2(os.path.join(ROOT, "web", "editor.html"), OUT)
    for dirpath, _, files in os.walk(os.path.join(ROOT, "lessons")):
        for f in files:
            if f.endswith(".json"):
                rel = os.path.relpath(os.path.join(dirpath, f), ROOT)
                os.makedirs(os.path.join(OUT, os.path.dirname(rel)), exist_ok=True)
                shutil.copy2(os.path.join(ROOT, rel), os.path.join(OUT, rel))

    # index.wasm in parts.
    data = open(os.path.join(WEB, "index.wasm"), "rb").read()
    parts = []
    for i in range(0, len(data), PART):
        name = f"index.wasm.part{len(parts)}"
        open(os.path.join(OUT, name), "wb").write(data[i:i + PART])
        parts.append(name)
    manifest = {"parts": parts, "size": len(data), "etag": hashlib.sha256(data).hexdigest()[:32]}
    json.dump(manifest, open(os.path.join(OUT, "index.wasm.parts.json"), "w"))

    # Only /index.wasm goes through the function; always revalidate so a new build or an
    # edited lesson shows up on a normal refresh (unchanged files still come back as 304s).
    json.dump({"version": 1, "include": ["/index.wasm"], "exclude": []},
              open(os.path.join(OUT, "_routes.json"), "w"))
    with open(os.path.join(OUT, "_headers"), "w", newline="\n") as f:
        f.write("/*\n  Cache-Control: no-cache\n")

    big = [n for n in os.listdir(OUT) if os.path.getsize(os.path.join(OUT, n)) > 25 * 1024 * 1024
           if os.path.isfile(os.path.join(OUT, n))]
    if big:
        sys.exit(f"Still too big for Cloudflare Pages: {big}")
    print(f"Ready in {OUT} (index.wasm split into {len(parts)} parts).")
    print("Deploy with:  cd cloudflare  then  npx wrangler pages deploy")


if __name__ == "__main__":
    main()
