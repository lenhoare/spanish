// Fast checks of the pieces that must never be wrong. Run: npm test
import { test } from "node:test";
import assert from "node:assert/strict";
import { features, isOn } from "../src/flags.js";
import { hmacHex, safeNext, sign, unsign } from "../src/util.js";
import { verifyStripeSignature } from "../src/billing.js";
import { normaliseCode } from "../src/classes.js";
import { PROVIDERS, emailIn } from "../src/auth.js";

const ALL_SECRETS = {
  GOOGLE_CLIENT_ID: "id", GOOGLE_CLIENT_SECRET: "s", SESSION_SECRET: "x", DB: {},
  MICROSOFT_CLIENT_ID: "mid", MICROSOFT_CLIENT_SECRET: "ms",
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
  const f = features({ ...ALL_SECRETS, SESSION_SECRET: "", FEATURE_AUTH: "on", FEATURE_REQUIRE_ACCESS: "on" });
  assert.equal(f.auth, false);
  assert.equal(f.requireAccess, false);
  assert.ok(f.problems.length >= 1);
  // Half-set-up Google: its button is hidden, Microsoft still works.
  const h = features({ ...ALL_SECRETS, GOOGLE_CLIENT_SECRET: "", FEATURE_AUTH: "on" });
  assert.deepEqual([h.auth, h.providers], [true, ["microsoft"]]);
  assert.ok(h.problems.some((p) => p.includes("GOOGLE_CLIENT_SECRET")));
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

test("sign-in providers: offered only when set up and switched on", () => {
  const on = { ...ALL_SECRETS, FEATURE_AUTH: "on" };
  assert.deepEqual(features(on).providers, ["google", "microsoft"]);
  assert.deepEqual(features({ ...on, SIGNIN_GOOGLE: "off" }).providers, ["microsoft"]);
  assert.deepEqual(features({ ...on, MICROSOFT_CLIENT_ID: "", MICROSOFT_CLIENT_SECRET: "" }).providers, ["google"]);
  const none = features({ ...on, SIGNIN_GOOGLE: "off", SIGNIN_MICROSOFT: "off" });
  assert.equal(none.auth, false);
  assert.deepEqual(none.providers, []);
  assert.deepEqual(features({ ...ALL_SECRETS }).providers, []);
});

const TID = "11111111-2222-3333-4444-555555555555";
const ms = (claims, env = {}) => PROVIDERS.microsoft.identity(
  { tid: TID, iss: `https://login.microsoftonline.com/${TID}/v2.0`, ...claims }, env);

test("Microsoft: school accounts sign in; email trusted only when Microsoft vouches or the school is listed", () => {
  const a = ms({ preferred_username: "Miss.Cleary@School.org.uk", name: "Miss Cleary" });
  assert.equal(a.email, "Miss.Cleary@School.org.uk");
  assert.equal(a.emailTrusted, false);
  assert.equal(ms({ email: "a@school.uk", xms_edov: true }).emailTrusted, true);
  assert.equal(ms({ email: "a@school.uk" }, { MICROSOFT_TRUSTED_TENANTS: TID.toUpperCase().toLowerCase() }).emailTrusted, true);
});

test("Microsoft: issuer, tenant and personal-account checks", () => {
  assert.equal(ms({ email: "a@b.c", iss: "https://login.microsoftonline.com/other/v2.0" }).error, "wrong issuer");
  assert.equal(ms({ email: "a@b.c" }, { MICROSOFT_TENANT: "99999999-2222-3333-4444-555555555555" }).error, "other organisation");
  assert.equal(ms({ email: "a@b.c" }, { MICROSOFT_TENANT: TID }).error, undefined);
  const consumer = "9188040d-6c67-4c5b-b112-36a304b66dad";
  const personal = { tid: consumer, iss: `https://login.microsoftonline.com/${consumer}/v2.0`, email: "x@outlook.com" };
  assert.equal(PROVIDERS.microsoft.identity(personal, {}).error, "personal account");
  assert.equal(PROVIDERS.microsoft.identity(personal, { MICROSOFT_TENANT: "common" }).error, undefined);
  assert.equal(ms({}).error, "no email address");
});

test("Google: needs a verified email", () => {
  const g = (c) => PROVIDERS.google.identity({ iss: "https://accounts.google.com", ...c });
  assert.equal(g({ email: "a@gmail.com", email_verified: true }).emailTrusted, true);
  assert.equal(g({ email: "a@gmail.com", email_verified: false }).error, "email not verified");
  assert.equal(g({ email: "a@gmail.com" }).error, "email not verified");
});

test("admin / free-plan email lists ignore untrusted emails", () => {
  assert.equal(emailIn({ email: "Boss@School.uk", email_trusted: 1 }, "boss@school.uk, x@y.z"), true);
  assert.equal(emailIn({ email: "boss@school.uk", email_trusted: 0 }, "boss@school.uk"), false);
  assert.equal(emailIn(null, "boss@school.uk"), false);
});
