// Gets build/web ready to upload, after the Godot export (see README "Build the web version"):
//   - copies config.json, config_retos.json, games.json, the lessons folder, the editor and the
//     Teacher Games page (web/games/)
//     next to index.html (the game fetches these from the server, so they can change without
//     a rebuild)
//   - moves any file over Cloudflare's 25 MiB per-file limit (usually index.wasm) to
//     build/large/, to go to R2 storage instead (cloudflare: `npm run upload-large`)
//
// Usage:  node tools/prepare_site.mjs        (also run by `npm run deploy` in cloudflare/)

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const WEB = path.join(ROOT, "build", "web");
const LARGE = path.join(ROOT, "build", "large");
const LIMIT = 25 * 1024 * 1024 - 64 * 1024; // a little under Cloudflare's 25 MiB

if (!fs.existsSync(path.join(WEB, "index.html"))) {
  console.error("No game in build/web yet - export it from Godot first (see README.md, 'Build the web version').");
  process.exit(1);
}

function copy(rel, filter = () => true) {
  const src = path.join(ROOT, rel);
  if (!fs.existsSync(src)) return;
  fs.cpSync(src, path.join(WEB, rel), {
    recursive: true,
    filter: (p) => fs.statSync(p).isDirectory() || filter(p),
  });
}

for (const f of ["config.json", "config_retos.json", "games.json"]) copy(f);
copy("lessons", (p) => p.endsWith(".json"));
fs.copyFileSync(path.join(ROOT, "web", "editor.html"), path.join(WEB, "editor.html"));
// The Teacher Games page (mscleary.com/games/) and its list. The games themselves are published
// to R2 from their own repositories (cloudflare/game-template/README.md).
fs.cpSync(path.join(ROOT, "web", "games"), path.join(WEB, "games"), { recursive: true });

fs.mkdirSync(LARGE, { recursive: true });
let moved = 0;
for (const name of fs.readdirSync(WEB)) {
  const p = path.join(WEB, name);
  const st = fs.statSync(p);
  if (st.isFile() && st.size > LIMIT) {
    fs.renameSync(p, path.join(LARGE, name));
    console.log(`Moved ${name} (${(st.size / 1048576).toFixed(1)} MiB) to build/large/ - it is served from R2.`);
    moved++;
  }
}
const waiting = fs.readdirSync(LARGE);
console.log(`build/web is ready.${waiting.length ? ` ${waiting.length} large file(s) in build/large/ for R2.` : ""}`);
if (!moved && waiting.length) console.log("(No new large files this time; build/large/ still has the previous ones.)");
