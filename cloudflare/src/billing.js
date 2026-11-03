// Stripe subscriptions for teachers (a few pounds a month). Only active with FEATURE_PAYMENTS.
//
//   POST /api/billing/checkout   -> {url} of a Stripe Checkout page for the monthly plan
//   POST /api/billing/portal     -> {url} of Stripe's customer portal (change card, cancel, invoices)
//   POST /api/billing/webhook    <- Stripe tells us about subscription changes (signed)
//
// Stripe hosts the card forms, so card details never touch this site.

import { listOf, isOn } from "./flags.js";
import { hmacHex, json, now, timingSafeEqual } from "./util.js";

const API = "https://api.stripe.com/v1";
const GOOD_STATUSES = new Set(["active", "trialing", "past_due"]); // past_due = grace while Stripe retries the card
const GOOD_SQL = [...GOOD_STATUSES].map((s) => `'${s}'`).join(", ");

/** Stripe's form encoding: {a: {b: 1}} -> a[b]=1 */
function form(params, prefix = "", out = new URLSearchParams()) {
  for (const [k, v] of Object.entries(params)) {
    if (v === undefined || v === null) continue;
    const key = prefix ? `${prefix}[${k}]` : k;
    if (typeof v === "object") form(v, key, out);
    else out.append(key, String(v));
  }
  return out;
}

async function stripe(env, method, path, params) {
  const res = await fetch(API + path, {
    method,
    headers: {
      authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
      ...(params ? { "content-type": "application/x-www-form-urlencoded" } : {}),
    },
    body: params ? form(params) : undefined,
  });
  const data = await res.json();
  if (!res.ok) throw new Error(`Stripe ${method} ${path}: ${data?.error?.message || res.status}`);
  return data;
}

function siteUrl(env, request) {
  return (env.PUBLIC_URL || new URL(request.url).origin).replace(/\/+$/, "");
}

/** What the teacher's plan looks like, for the teachers page and for access checks. */
export async function planFor(env, flags, user) {
  if (!user) return { active: false, reason: "signed-out" };
  if (!flags.payments) return { active: true, reason: "payments-off" };
  if (listOf(env.COMPLIMENTARY_EMAILS).includes(user.email.toLowerCase())) return { active: true, reason: "complimentary" };
  const sub = await env.DB.prepare("SELECT * FROM subscriptions WHERE user_id = ?").bind(user.id).first();
  if (!sub) return { active: false, reason: "no-subscription" };
  return {
    active: GOOD_STATUSES.has(sub.status),
    reason: "subscription",
    status: sub.status,
    currentPeriodEnd: sub.current_period_end,
    cancelAtPeriodEnd: !!sub.cancel_at_period_end,
  };
}

export async function handleBilling(request, env, path, user) {
  if (path === "/api/billing/webhook") return webhook(request, env);
  if (!user) return json({ error: "Please sign in first." }, 401);

  if (path === "/api/billing/checkout") {
    const customer = await customerFor(env, user);
    const base = siteUrl(env, request);
    const params = {
      mode: "subscription",
      customer,
      client_reference_id: user.id,
      line_items: { 0: { price: env.STRIPE_PRICE_ID, quantity: 1 } },
      allow_promotion_codes: "true", // lets you hand out free/discounted months with Stripe promo codes
      subscription_data: { metadata: { user_id: user.id } },
      success_url: `${base}/teachers?billing=success`,
      cancel_url: `${base}/teachers?billing=cancelled`,
    };
    const trialDays = parseInt(env.STRIPE_TRIAL_DAYS || "0", 10);
    if (trialDays > 0) params.subscription_data.trial_period_days = trialDays;
    if (isOn(env.STRIPE_AUTOMATIC_TAX)) params.automatic_tax = { enabled: "true" };
    const session = await stripe(env, "POST", "/checkout/sessions", params);
    return json({ url: session.url });
  }

  if (path === "/api/billing/portal") {
    if (!user.stripe_customer_id) return json({ error: "No billing account yet." }, 400);
    const portal = await stripe(env, "POST", "/billing_portal/sessions", {
      customer: user.stripe_customer_id,
      return_url: `${siteUrl(env, request)}/teachers`,
    });
    return json({ url: portal.url });
  }
  return null;
}

async function customerFor(env, user) {
  if (user.stripe_customer_id) return user.stripe_customer_id;
  const c = await stripe(env, "POST", "/customers", {
    email: user.email,
    name: user.name || undefined,
    metadata: { user_id: user.id },
  });
  await env.DB.prepare("UPDATE users SET stripe_customer_id = ? WHERE id = ?").bind(c.id, user.id).run();
  return c.id;
}

// ------------------------------------------------------------------ webhook

/** Checks Stripe's signature header: "t=timestamp,v1=hmac[,v1=...]". */
export async function verifyStripeSignature(payload, header, secret, toleranceSeconds = 300, nowSeconds = now()) {
  if (!header) return false;
  const parts = header.split(",").map((p) => p.split("="));
  const t = parts.find(([k]) => k === "t")?.[1];
  const sigs = parts.filter(([k]) => k === "v1").map(([, v]) => v);
  if (!t || !sigs.length) return false;
  if (Math.abs(nowSeconds - parseInt(t, 10)) > toleranceSeconds) return false;
  const expected = await hmacHex(secret, `${t}.${payload}`);
  return sigs.some((s) => timingSafeEqual(s, expected));
}

async function webhook(request, env) {
  const payload = await request.text();
  if (!(await verifyStripeSignature(payload, request.headers.get("stripe-signature"), env.STRIPE_WEBHOOK_SECRET))) {
    return json({ error: "bad signature" }, 400);
  }
  const event = JSON.parse(payload);
  const obj = event.data?.object || {};
  let subscriptionId = null;
  if (event.type === "checkout.session.completed" && obj.mode === "subscription") subscriptionId = obj.subscription;
  if (event.type?.startsWith("customer.subscription.")) subscriptionId = obj.id;
  if (event.type === "invoice.paid" || event.type === "invoice.payment_failed") {
    subscriptionId = obj.subscription || obj.parent?.subscription_details?.subscription;
  }
  if (subscriptionId) {
    // Always re-read the subscription from Stripe: events can arrive out of order, and this
    // way the stored status is whatever Stripe says right now.
    const sub = await stripe(env, "GET", `/subscriptions/${subscriptionId}`);
    await saveSubscription(env, sub, obj.client_reference_id);
  }
  return json({ received: true });
}

async function saveSubscription(env, sub, referenceUserId) {
  let userId = sub.metadata?.user_id || referenceUserId;
  if (!userId) {
    const u = await env.DB.prepare("SELECT id FROM users WHERE stripe_customer_id = ?").bind(sub.customer).first();
    userId = u?.id;
  }
  if (!userId) {
    console.warn("[billing] subscription for unknown customer", sub.customer);
    return;
  }
  // Newer Stripe API versions keep the billing period on the subscription item.
  const periodEnd = sub.current_period_end ?? sub.items?.data?.[0]?.current_period_end ?? null;
  await env.DB.prepare(
    `INSERT INTO subscriptions (user_id, stripe_subscription_id, status, current_period_end, cancel_at_period_end, updated_at)
     VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT (user_id) DO UPDATE SET stripe_subscription_id = excluded.stripe_subscription_id,
       status = excluded.status, current_period_end = excluded.current_period_end,
       cancel_at_period_end = excluded.cancel_at_period_end, updated_at = excluded.updated_at
     -- A late event about an old, ended subscription must not replace a newer live one.
     WHERE subscriptions.stripe_subscription_id = excluded.stripe_subscription_id
        OR excluded.status IN (${GOOD_SQL})
        OR subscriptions.status NOT IN (${GOOD_SQL})`,
  )
    .bind(userId, sub.id, sub.status, periodEnd, sub.cancel_at_period_end ? 1 : 0, now())
    .run();
  await env.DB.prepare("UPDATE users SET stripe_customer_id = COALESCE(stripe_customer_id, ?) WHERE id = ?")
    .bind(sub.customer, userId)
    .run();
}
