// Dev tool: drives headless Chrome over the DevTools protocol to smoke-test the web build.
// Usage: node tools/webtest.mjs <url> <outdir> [phone]
//
// Only ONE test Chrome ever runs: any leftover from a previous run is killed first, and the
// whole Chrome process tree is killed when this script ends (success, error, Ctrl+C, or the
// 2-minute watchdog). Test Chromes are recognised by their "lesson-island-cdp" profile folder,
// so your normal Chrome windows are never touched.
import { spawn, execSync } from "node:child_process";
import { writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

const MARKER = "lesson-island-cdp";

function killTestChromes() {
  try {
    execSync(
      `powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \\"Name='chrome.exe'\\" | ` +
        `Where-Object { $_.CommandLine -match '${MARKER}' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"`,
      { stdio: "ignore" },
    );
  } catch {}
}

const [url, outDir, mode] = process.argv.slice(2);
const phone = mode === "phone" || mode === "askbox" || mode === "phonecard";
mkdirSync(outDir, { recursive: true });
killTestChromes();
const port = 9333;
const chrome = spawn("C:/Program Files/Google/Chrome/Application/chrome.exe", [
  "--headless=new", `--remote-debugging-port=${port}`, `--user-data-dir=${join(tmpdir(), MARKER)}`,
  "--enable-unsafe-swiftshader", "--use-angle=swiftshader", "--window-size=1280,720", "--autoplay-policy=no-user-gesture-required", "about:blank",
]);
let cleanedUp = false;
function cleanup() {
  if (cleanedUp) return;
  cleanedUp = true;
  try { execSync(`taskkill /PID ${chrome.pid} /T /F`, { stdio: "ignore" }); } catch {}
  killTestChromes();
}
process.on("exit", cleanup);
for (const sig of ["SIGINT", "SIGTERM", "SIGBREAK"]) process.on(sig, () => process.exit(130));
process.on("uncaughtException", (e) => { console.error(e); process.exit(1); });
process.on("unhandledRejection", (e) => { console.error(e); process.exit(1); });
setTimeout(() => { console.error("Watchdog: test took over 2 minutes, stopping."); process.exit(1); }, 120_000).unref();
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let targets;
for (let i = 0; i < 50; i++) {
  try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {}
  await sleep(200);
}
const page = targets.find((t) => t.type === "page");
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener("open", r));
let id = 0;
const pending = new Map();
const logs = [];
ws.addEventListener("message", (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
  if (msg.method === "Runtime.consoleAPICalled") logs.push(msg.params.type + ": " + msg.params.args.map((a) => a.value ?? a.description).join(" "));
  if (msg.method === "Runtime.exceptionThrown") logs.push("EXCEPTION: " + JSON.stringify(msg.params.exceptionDetails.text));
});
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const shot = async (name) => {
  const r = await send("Page.captureScreenshot", { format: "png" });
  writeFileSync(join(outDir, name), Buffer.from(r.result.data, "base64"));
  console.log("SHOT", name);
};
const W = phone ? 844 : 1280, H = phone ? 390 : 720;
const tap = async (x, y) => {
  if (phone) {
    await send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [{ x, y }] });
    await sleep(80);
    await send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
  } else {
    await send("Input.dispatchMouseEvent", { type: "mousePressed", x, y, button: "left", clickCount: 1 });
    await sleep(80);
    await send("Input.dispatchMouseEvent", { type: "mouseReleased", x, y, button: "left", clickCount: 1 });
  }
};

await send("Runtime.enable");
await send("Page.enable");
if (phone) {
  await send("Emulation.setDeviceMetricsOverride", { width: W, height: H, deviceScaleFactor: 2, mobile: true });
  await send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 });
}
await send("Page.navigate", { url });
// Wait until the Godot canvas is running (engine logs "Godot Engine v...")
for (let i = 0; i < 120 && !logs.some((l) => l.includes("Godot Engine")); i++) await sleep(500);
await sleep(6000);
await shot(`${mode || "desktop"}_1_title.png`);
if (mode === "phonecard") {
  // Phone: Play, then (?devcard=1) a typed question card opens as a strip at the top.
  // Tap its answer field, type with the "phone keyboard", check the card shows the text.
  await tap(Math.round(W * 0.21), Math.round(H * 0.85));
  await sleep(2500);
  await tap(Math.round(W * 0.19), Math.round(H * 0.36));   // Isla 1
  await sleep(7000);
  await shot("phonecard_1_open.png");
  await tap(Math.round(W * 0.35), 70);
  await sleep(500);
  const f = await send("Runtime.evaluate", { expression: "document.activeElement && document.activeElement.tagName + ':' + document.activeElement.type", returnByValue: true });
  console.log("FOCUSED:", f.result.result.value);
  await send("Input.insertText", { text: "bailo" });
  await sleep(700);
  await shot("phonecard_2_typed.png");
  const fs = await send("Runtime.evaluate", { expression: "!!document.fullscreenElement", returnByValue: true });
  console.log("FULLSCREEN:", fs.result.result.value);
  ws.close();
  process.exit(0);
}
if (mode === "askbox") {
  // The phone text box: open it, type, press OK, check the game would get the answer.
  await send("Runtime.evaluate", { expression: "window.liAsk('Translate into Spanish: \u0022I went\u0022', 'fu', false)" });
  await sleep(600);
  await shot("askbox_1_open.png");
  const r = await send("Runtime.evaluate", { expression: "document.getElementById('li-in').value = 'fui'; document.getElementById('li-ok').click(); window.liState + ':' + window.liValue", returnByValue: true });
  console.log("ASKBOX result:", r.result.result.value);
  ws.close();
  process.exit(0);
}
if (mode === "chooser") {
  // Pick the first game on the chooser and look at its title screen.
  await tap(640, 275);
  await sleep(4000);
  await shot("chooser_2_title.png");
  ws.close();
  process.exit(0);
}
// Play button sits at the bottom of the left-hand title panel.
await tap(phone ? Math.round(W * 0.21) : 290, phone ? Math.round(H * 0.85) : 545);
await sleep(5000);
await shot(`${mode || "desktop"}_2_game.png`);
if (phone) {
  // Hold the joystick forward for a second, then tap jump.
  const jx = 100, jy = H - 90;
  await send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [{ x: jx, y: jy, id: 1 }] });
  for (let k = 0; k < 10; k++) { await send("Input.dispatchTouchEvent", { type: "touchMove", touchPoints: [{ x: jx, y: jy - 5 * k, id: 1 }] }); await sleep(100); }
  await send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
} else {
  await send("Input.dispatchKeyEvent", { type: "rawKeyDown", code: "KeyW", key: "w", windowsVirtualKeyCode: 87 });
  await sleep(1200);
  await send("Input.dispatchKeyEvent", { type: "keyUp", code: "KeyW", key: "w", windowsVirtualKeyCode: 87 });
}
await sleep(1500);
await shot(`${mode || "desktop"}_3_moved.png`);
console.log(logs.filter((l) => !l.includes("WebGL")).slice(0, 40).join("\n"));
ws.close();
process.exit(0);   // triggers cleanup()
