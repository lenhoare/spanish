// Fast checks of the pieces that must never be wrong. Run: npm test
import { test } from "node:test";
import assert from "node:assert/strict";
import { features, isOn } from "../src/flags.js";
import { hmacHex, safeNext, sign, unsign } from "../src/util.js";
import { verifyStripeSignature } from "../src/billing.js";
import { normaliseCode } from "../src/classes.js";

const ALL_SECRETS = {
  GOOGLE_CLIENT_ID: "id", GOOGLE_CLIENT_SECRET: "s", SESSION_SECRET: "x", DB: {},
  STRIPE_SECRET_KEY: "sk", STRIPE_WEBHOOK_SECRET: "wh", STRIPE_PRICE_ID: "price", ADMIN_EMAILS: "a@b.c",
};

test("everything is off by default, even with all secrets present", () => {
  const f = features({ ...ALL_SECRETS });
  assert.deepEqual([f.auth, f.payments, f.requireAccess, f.protectEditor], [false, false, false, false]);
});

test("auth off switches every other feature off", () => {
  const f = features({ ...ALL_SECRETS, FEATURE_AUTH: "off", FEATURE_PAYMENTS: "on", FEATURE_REQUIRE_ACCESS: "on", FEATURE_PROTECT_EDITOR: "on" });
  assert.deepEqual([f.auth, f.payments, f.requireAccess, f.protectEditor], [false, false, false, false]);
});

test("all on with secrets", () => {
  const f = features({ ...ALL_SECRETS, FEATURE_AUTH: "on", FEATURE_PAYMENTS: "true", FEATURE_REQUIRE_ACCESS: "1", FEATURE_PROTECT_EDITOR: "yes" });
  assert.deepEqual([f.auth, f.payments, f.requireAccess, f.protectEditor], [true, true, true, true]);
});

test("a missing secret keeps that feature off (fails open)", () => {
  const f = features({ ...ALL_SECRETS, GOOGLE_CLIENT_SECRET: "", FEATURE_AUTH: "on", FEATURE_REQUIRE_ACCESS: "on" });
  assert.equal(f.auth, false);
  assert.equal(f.requireAccess, false);
  assert.ok(f.problems.length >= 1);
  const g = features({ ...ALL_SECRETS, STRIPE_PRICE_ID: "", FEATURE_AUTH: "on", FEATURE_PAYMENTS: "on" });
  assert.equal(g.auth, true);
  assert.equal(g.payments, false);
});

test("isOn", () => {
  for (const v of ["on", "ON", " true ", "1", "yes"]) assert.equal(isOn(v), true);
  for (const v of ["off", "", undefined, "0", "no", "false"]) assert.equal(isOn(v), false);
});

test("signed values round-trip and reject tampering / expiry", async () => {
  const t = await sign("secret", { a: 1 }, 60);
  assert.equal((await unsign("secret", t)).a, 1);
  assert.equal(await unsign("other", t), null);
  assert.equal(await unsign("secret", t.slice(0, -1) + (t.endsWith("0") ? "1" : "0")), null);
  assert.equal(await unsign("secret", await sign("secret", { a: 1 }, -1)), null);
  assert.equal(await unsign("secret", "garbage"), null);
});

test("redirects stay on this site", () => {
  assert.equal(safeNext("/?game=retos"), "/?game=retos");
  assert.equal(safeNext("//evil.com"), "/");
  assert.equal(safeNext("/\\evil.com"), "/");
  assert.equal(safeNext("https://evil.com"), "/");
  assert.equal(safeNext(""), "/");
});

test("Stripe webhook signatures", async () => {
  const payload = '{"id":"evt_1"}';
  const t = 1_700_000_000;
  const sig = await hmacHex("whsec_test", `${t}.${payload}`);
  assert.equal(await verifyStripeSignature(payload, `t=${t},v1=${sig}`, "whsec_test", 300, t + 10), true);
  assert.equal(await verifyStripeSignature(payload, `t=${t},v1=bad,v1=${sig}`, "whsec_test", 300, t), true);
  assert.equal(await verifyStripeSignature(payload, `t=${t},v1=${sig}`, "whsec_other", 300, t), false);
  assert.equal(await verifyStripeSignature(payload + " ", `t=${t},v1=${sig}`, "whsec_test", 300, t), false);
  assert.equal(await verifyStripeSignature(payload, `t=${t},v1=${sig}`, "whsec_test", 300, t + 301), false);
  assert.equal(await verifyStripeSignature(payload, null, "whsec_test"), false);
});

test("class codes are forgiving about spaces and case", () => {
  assert.equal(normaliseCode(" ab-c 123 "), "ABC123");
});
