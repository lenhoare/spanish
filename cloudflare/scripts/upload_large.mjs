// Uploads build/large/* (game files over 25 MiB, e.g. index.wasm) to the R2 bucket the Worker
// serves them from. Run after `npm run site`; `npm run deploy` does both.

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const LARGE = path.join(HERE, "..", "build", "large");
const BUCKET = process.env.R2_BUCKET || "lesson-island-files";

const files = fs.existsSync(LARGE) ? fs.readdirSync(LARGE).filter((f) => fs.statSync(path.join(LARGE, f)).isFile()) : [];
if (!files.length) {
  console.log("No large files to upload.");
  process.exit(0);
}
const wrangler = path.join(HERE, "node_modules", "wrangler", "bin", "wrangler.js");
for (const f of files) {
  console.log(`Uploading ${f} to R2 bucket ${BUCKET}...`);
  execFileSync(process.execPath, [wrangler, "r2", "object", "put", `${BUCKET}/${f}`, "--file", path.join(LARGE, f), "--remote"], {
    stdio: "inherit",
    cwd: HERE,
  });
}
