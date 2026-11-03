# Hosting on Cloudflare

A small Cloudflare Worker serves the game. It also has some optional extras, and **every one of
them is off unless you switch it on**:

| Switch (in `wrangler.jsonc`) | What it does when `"on"` |
|---|---|
| `FEATURE_AUTH` | **Master switch.** Teachers can sign in with Google at `/teachers`. While it's off, all the others are off too, and `/teachers`, `/join`, `/auth/*` and `/api/*` don't exist (404). |
| `FEATURE_PAYMENTS` | Teachers subscribe monthly through Stripe. They need a subscription before they can make classes. |
| `FEATURE_REQUIRE_ACCESS` | The game is no longer open: students need a class code from a teacher (or the teacher's join link), and teachers can play when signed in. |
| `FEATURE_PROTECT_EDITOR` | `editor.html` needs a Google sign-in from someone in `ADMIN_EMAILS`. |

With everything off (the live-site settings at the top of `wrangler.jsonc`), the site is a
plain open website, just like any static host. Check what's on at any time:
`https://<your-site>/api/features`.

If a switch is on but a secret it needs is missing, that feature stays **off** (and the Worker
logs say why). A half-finished setup leaves the game playable rather than locking everyone out.

**Students never have accounts.** They type a class code, which sets a cookie. No student
names, emails or other personal data are stored. Teachers' Google name/email and their Stripe
customer id are the only personal data kept.

There are two separate sites:
- **live** (`npm run deploy`): top-level settings, everything off. Use it for alpha/beta.
- **staging** (`npm run deploy:staging`): the `env.staging` settings, with sign-in, payments
  and class codes on, using **Stripe test mode**. Use it to try the features without affecting
  the real site. It gets its own address (`lesson-island-staging.<you>.workers.dev`) and its own
  database.

---

## 1. First deploy (open website, nothing else needed)

You need [Node.js](https://nodejs.org) and a free Cloudflare account.

1. Export the game from Godot into `build/web` (see the main README).
2. In a terminal:
   ```
   cd cloudflare
   npm install
   npx wrangler login
   npm run deploy
   ```
   `npm run deploy` copies the config and lessons into `build/web`, uploads the site, and puts
   any file over 25 MiB (Godot's `index.wasm` usually is) into R2 storage. Cloudflare doesn't
   allow single site files over 25 MiB, so the Worker serves those from R2 instead. The
   database and R2 bucket are created automatically the first time.
3. The site is at `https://lesson-island.<your-subdomain>.workers.dev`. To use your own domain,
   go to the Cloudflare dashboard → Workers & Pages → lesson-island → Settings → Domains & Routes.

Changing lessons or config later: edit the files, then `npm run deploy` again. You don't need to
re-export from Godot.

If R2 isn't enabled on your account yet, the first deploy will ask you to enable it in the
dashboard (R2 has a free allowance: 10 GB storage, with no charge for downloads).

## 2. Turning on Google sign-in

1. Go to [Google Cloud console](https://console.cloud.google.com/) → create a project →
   **APIs & Services → OAuth consent screen**: External, app name "Lesson Island", your email.
   Scopes: just the defaults (`openid`, `email`, `profile`). These are non-sensitive scopes, so
   Google doesn't need to review the app.
2. **Credentials → Create credentials → OAuth client ID → Web application.**
   Authorised redirect URIs. Add one for each site you'll use:
   - `https://lesson-island-staging.<your-subdomain>.workers.dev/auth/google/callback`
   - `https://lesson-island.<your-subdomain>.workers.dev/auth/google/callback` (or your domain)
   - `http://localhost:8787/auth/google/callback` (for local testing)
3. Set the secrets (for staging, add `--env staging` to each command):
   ```
   npx wrangler secret put GOOGLE_CLIENT_ID
   npx wrangler secret put GOOGLE_CLIENT_SECRET
   npx wrangler secret put SESSION_SECRET      # any long random string
   ```
   To make a random string: `node -e "console.log(crypto.randomUUID()+crypto.randomUUID())"`
4. Create the database tables (one time, and again whenever a new file appears in `migrations/`):
   `npm run db:migrate` (or `npm run db:migrate:staging`).
5. Set `"FEATURE_AUTH": "on"` in `wrangler.jsonc` and deploy.

## 3. Turning on Stripe subscriptions

1. In the [Stripe dashboard](https://dashboard.stripe.com) (start in **Test mode**):
   **Product catalogue → Add product**, e.g. "Lesson Island for teachers", recurring,
   monthly, £3. Copy the **price id** (`price_...`) into `STRIPE_PRICE_ID` in `wrangler.jsonc`.
2. **Developers → Webhooks → Add endpoint**:
   - URL: `https://<your-site>/api/billing/webhook`
   - Events: `checkout.session.completed`, `customer.subscription.created`,
     `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.paid`,
     `invoice.payment_failed`
   - Copy the **signing secret** (`whsec_...`).
3. **Settings → Billing → Customer portal**: turn it on. This lets teachers cancel and update
   their card themselves.
4. Secrets:
   ```
   npx wrangler secret put STRIPE_SECRET_KEY       # sk_test_... (sk_live_... for real money)
   npx wrangler secret put STRIPE_WEBHOOK_SECRET
   ```
5. Set `"FEATURE_PAYMENTS": "on"` and deploy. To test a payment in test mode, use card
   `4242 4242 4242 4242`, any future date and any CVC.

Useful settings in `wrangler.jsonc`:
- `COMPLIMENTARY_EMAILS`: teachers (comma-separated emails) who get a free plan. Good for
  colleagues who helped with testing.
- `STRIPE_TRIAL_DAYS`: free trial length for new subscriptions (`"0"` = none).
- `STRIPE_AUTOMATIC_TAX`: `"on"` if you've set up Stripe Tax (for when you need to charge VAT).
- Promotion codes are allowed at checkout, so you can make discount or free-month codes in Stripe.

Moving to real payments: make the same product/price and webhook in **live mode**, and put the
live price id and live keys on the live site.

## 4. Requiring a class code

Set `"FEATURE_REQUIRE_ACCESS": "on"`. Then:
- Visitors without access are sent to `/join` to type a class code.
- Teachers make classes at `/teachers`, and each class gets a code like `8RHNUZ` and a link
  (`/join?code=8RHNUZ`) that lets students straight in. "New code" replaces a code that got
  shared too widely, and "Remove" stops the code working.
- If a teacher's subscription ends, their codes stop working on the students' next visit.
  Stripe's retry period (`past_due`) still counts as active, so a failed card doesn't cut a
  class off mid-lesson.

## Testing on your own computer

```
cd cloudflare
npm run dev            # live settings (everything off) at http://localhost:8787
npm test               # quick checks of the switches, signing and Stripe signatures
```
To try the features locally, copy `.dev.vars.example` to `.dev.vars.staging`, fill it in
(Stripe test keys), then run `npm run dev:features`.

## Costs (free tiers, November 2026)

The Workers free plan gives 100,000 requests a day. Loading the game takes about 15 requests, so
that's roughly 6,000 game loads a day. D1 and R2 free allowances are far beyond what this uses.
Stripe charges per transaction (around 1.5% + 20p for UK cards), and on a £3 payment that's
about 25p.

## Files

- `wrangler.jsonc`: switches, settings, the live and staging sites
- `src/flags.js`: how the switches combine
- `src/index.js`: routing and serving game files (from R2 for the big ones)
- `src/auth.js`: Google sign-in (OpenID Connect with PKCE). Microsoft can be added as another provider.
- `src/billing.js`: Stripe Checkout, customer portal, webhook
- `src/classes.js`, `src/access.js`: classes, join codes, and the gate in front of the game
- `src/pages/`: the `/teachers` and `/join` pages
- `migrations/`: database tables
- `../tools/prepare_site.mjs`: gets `build/web` ready (copies config/lessons/editor, moves big files)
