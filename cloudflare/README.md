# Putting the game online (misscleary.com on Cloudflare)

This is a step-by-step checklist. Do the steps in order; each one says what you'll see when it's
worked. Nothing here needs your own computer except a web browser: GitHub builds the game and
publishes it for you.

- **Part 1 (tonight):** the game live at **https://misscleary.com** as an open website (no sign-in, no payments).
- **Part 2 (tomorrow):** a private test copy at **https://staging.misscleary.com** with Google and
  Microsoft sign-in, Stripe payments (test mode, no real money) and class codes switched on.
- **Part 3 (later):** switching features on and off for the real site.

---

## How it fits together

```
 you push to GitHub (main)
        │
        ▼
 GitHub Actions: Godot exports the game ──► Cloudflare Worker "lesson-island"      ──► misscleary.com
                 (.github/workflows/         + R2 storage for the 37 MB index.wasm
                  deploy.yml)               + D1 database (teachers, classes; unused while features are off)
```

The **switches** (what's on/off) live in `cloudflare/wrangler.jsonc` in GitHub. Changing one is
just editing that file on github.com and saving; the site updates itself a few minutes later.
The **secrets** (passwords and keys from Google, Microsoft and Stripe) are typed into the Cloudflare
dashboard once and never go in GitHub.

| Switch | When `"on"` |
|---|---|
| `FEATURE_AUTH` | **Master switch.** Teachers can sign in at `/teachers`. While it's `"off"`, everything below is off as well, and `/teachers`, `/join`, `/auth/…` and `/api/…` don't exist. |
| `SIGNIN_GOOGLE`, `SIGNIN_MICROSOFT` | Which sign-in buttons to show (each also needs its secrets). |
| `FEATURE_PAYMENTS` | Teachers subscribe monthly with Stripe before they can make classes. |
| `FEATURE_REQUIRE_ACCESS` | The game stops being open: students need their teacher's class code or link. |
| `FEATURE_PROTECT_EDITOR` | `/editor` needs a sign-in from someone in `ADMIN_EMAILS`. |

If a switch is on but a secret it needs is missing, that feature quietly stays **off**, so a
half-finished setup never locks students out. To see what's really on, visit
`https://misscleary.com/api/features`.

Students never have accounts and no student data is stored. Teachers' name and email (and Stripe
customer number, if they pay) are the only personal data.

---

# Part 1: the open website (tonight)

### 1.1 Put misscleary.com on Cloudflare (≈15 min, then a wait)

1. Log in at [dash.cloudflare.com](https://dash.cloudflare.com) → **Add a domain** → type
   `misscleary.com` → choose the **Free** plan.
2. Cloudflare shows the DNS records it found at Porkbun. **Delete** any records for
   `misscleary.com` and `www` (type A, AAAA, ALIAS or CNAME). They're Porkbun's "parked"
   page and would block the game from using the address. Keep any **MX** or **TXT** records if
   you've set up email for the domain.
3. Cloudflare shows **two nameservers**, like `xxx.ns.cloudflare.com`. Keep that tab open.
4. In another tab, log in to **Porkbun** → **Domain Management** → misscleary.com → **Details**:
   - If **DNSSEC** is on, turn it **off** first. If it's left on, the domain stops working after the switch.
   - **Authoritative Nameservers** → **Edit** → delete Porkbun's ones, paste Cloudflare's two → **Submit**.
5. Back in Cloudflare, click **Check nameservers**. It usually takes 10-60 minutes (occasionally
   longer). Cloudflare emails you when misscleary.com is **Active**. You can carry on with 1.2-1.4 meanwhile.

### 1.2 Turn on R2 storage (2 min)

Godot's `index.wasm` is 37 MB, and Cloudflare only allows 25 MB per website file, so it's kept in
Cloudflare's R2 storage instead. In the dashboard: **Storage & Databases → R2 → Purchase R2 Plan**
(the free tier: 10 GB free, which is plenty). It asks for a card, but you won't be charged at this size.

### 1.3 Make a Cloudflare API token for GitHub (5 min)

This lets GitHub publish to your Cloudflare account, and nothing else.

1. Cloudflare dashboard → your profile icon (top right) → **Profile** → **API Tokens** → **Create Token**.
2. Next to **Edit Cloudflare Workers**, click **Use template**.
3. Under **Permissions**, click **+ Add more** and add these two (if they're not already there):
   - `Account` · `D1` · `Edit`
   - `Zone` · `DNS` · `Edit`
4. **Account Resources**: Include → your account. **Zone Resources**: Include → Specific zone → `misscleary.com`.
5. **Continue to summary** → **Create Token** → **copy the token** (it's only shown once).
6. Also copy your **Account ID**: dashboard home → **Workers & Pages**. It's in the right-hand column
   (or in the browser address bar: `dash.cloudflare.com/<this-long-number>/...`).

### 1.4 Give them to GitHub (3 min)

On github.com → the `spanish` repository → **Settings** → **Secrets and variables** → **Actions**
→ **New repository secret**, twice:

| Name | Secret |
|---|---|
| `CLOUDFLARE_API_TOKEN` | the token from 1.3 |
| `CLOUDFLARE_ACCOUNT_ID` | the account ID from 1.3 |

### 1.5 Publish (wait for the "Active" email from 1.1 first)

Merge the pull request with this work into `main`. That's the publish button from now on: every
change that lands on `main` rebuilds and republishes the site.

Watch it on github.com → **Actions** → **Build and deploy**. It takes about 3 minutes; a green tick
means it's live. (The first run downloads Godot, so it's slower; later runs are quicker.)

**Check:** open https://misscleary.com - the island picker should appear. https://www.misscleary.com
should jump to the same place, and https://misscleary.com/api/features should say everything is `false`.

If the run goes red, click it, open the red step and read the last lines. Common ones:
- *"Authentication error"*: the token or account ID in 1.4 is wrong, or missing a permission from 1.3.
- *"…custom domain… zone…"*: misscleary.com isn't Active on Cloudflare yet (1.1). Wait, then
  **Actions → Build and deploy → Re-run jobs**.
- *R2 / "Please enable R2"*: do 1.2.

### 1.6 Make the staging copy (2 min)

github.com → **Actions** → **Build and deploy** → **Run workflow** → target **staging** → **Run workflow**.
When it's green, https://staging.misscleary.com shows the game, open to anyone, just like the
real site. Its features are switched on but have no secrets yet, so they stay off (the
"fails safe" rule). They come alive one by one in Part 2.

---

# Part 2: set up the features on staging (tomorrow)

Secrets are added in the Cloudflare dashboard: **Workers & Pages** → **lesson-island-staging** →
**Settings** → **Variables and Secrets** → **+ Add** → Type **Secret** → name and value → **Deploy**.
(Use **Secret**, not "Text". Text values are replaced by `wrangler.jsonc` on every publish; secrets are kept.)

### 2.1 Session secret

Add `SESSION_SECRET`: any long random string (say 40+ random letters and numbers). It signs the
sign-in cookies. If you ever change it, everyone is signed out (harmless).

### 2.2 Google sign-in (≈15 min)

1. [console.cloud.google.com](https://console.cloud.google.com) → project picker → **New project** → "Miss Cleary".
2. **APIs & Services → OAuth consent screen** (may be called **Google Auth Platform → Branding**):
   - App name `Miss Cleary`, support email: yours. **Don't upload a logo** (a logo makes Google
     review the app, which takes weeks).
   - Audience: **External**. Authorised domain: `misscleary.com`.
   - Then **Audience → Publish app** ("In production"). Until then only listed test users can sign in.
     The app only asks for name and email, so Google doesn't need to review it.
3. **Credentials** (or **Clients**) → **Create client** → **Web application**, name "misscleary.com".
   **Authorised redirect URIs**, add both:
   - `https://staging.misscleary.com/auth/google/callback`
   - `https://misscleary.com/auth/google/callback`
4. Copy the **Client ID** and **Client secret** into the staging Worker as secrets
   `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`.

### 2.3 Microsoft sign-in, for schools on Teams / Microsoft 365 (≈20 min)

1. Go to [entra.microsoft.com](https://entra.microsoft.com) and sign in with a Microsoft account
   (a personal one is fine; **not** the school's, since this is your app, not theirs). If it says
   you don't have access, sign up for a free Azure account at [azure.microsoft.com/free](https://azure.microsoft.com/free),
   which creates your own directory (it asks for a card as an identity check).
2. **Applications → App registrations → New registration**:
   - Name: `Miss Cleary`
   - Supported account types: **Accounts in any organizational directory (Any Microsoft Entra ID tenant - Multitenant)**
   - Redirect URI: platform **Web**, `https://staging.misscleary.com/auth/microsoft/callback`
   - **Register**.
3. On the app's **Overview**, copy **Application (client) ID** → staging secret `MICROSOFT_CLIENT_ID`.
4. **Authentication** → **Add URI** → `https://misscleary.com/auth/microsoft/callback` → **Save**.
5. **Certificates & secrets → New client secret** → expires in 24 months → copy the **Value**
   (not the "Secret ID") → staging secret `MICROSOFT_CLIENT_SECRET`.
   **Put a reminder in your calendar for 23 months' time**: sign-in stops when it expires.
6. **Token configuration → Add optional claim → ID** → tick `email` and, if it's listed,
   `xms_edov` → **Add** (accept the prompt about Graph permissions).
7. Optional, makes the sign-in prompt show your domain: set `MICROSOFT_CLIENT_ID` on the **live**
   Worker (lesson-island) too, then **Branding & properties → Publisher domain → Verify a new domain** →
   `misscleary.com`. The Worker already serves the file Microsoft checks.

**About school IT.** Many schools only let staff sign in to apps that their IT team has approved.
If a teacher sees *"Need admin approval"*, the site shows a friendly message and they can use Google
instead. To approve it for the whole school, the school's IT admin opens this link once (put your
client ID in):
`https://login.microsoftonline.com/organizations/adminconsent?client_id=YOUR_CLIENT_ID`

**Optional settings** (in `wrangler.jsonc`, staging section):
- `MICROSOFT_TENANT`: `"organizations"` (default: any school or work account) or one school's
  tenant ID to allow only that school.
- `MICROSOFT_TRUSTED_TENANTS`: a school's tenant ID, so its staff emails count for `ADMIN_EMAILS`
  and `COMPLIMENTARY_EMAILS`. (Microsoft schools can put any email on an account without proving
  it, so these lists ignore Microsoft emails unless Microsoft confirms them (`xms_edov`) or the
  school is listed here.) To find a school's tenant ID, open
  `https://login.microsoftonline.com/THEIRSCHOOL.org.uk/v2.0/.well-known/openid-configuration`
  with the school's email domain in place of `THEIRSCHOOL.org.uk`. The long ID in `"issuer"` is it.

### 2.4 Stripe, in test mode (≈20 min)

1. Sign up at [stripe.com](https://dashboard.stripe.com/register). Make sure **Test mode** is on (toggle top right).
2. **Product catalogue → + Add product**: "Miss Cleary for teachers", **Recurring**, **Monthly**,
   e.g. **£3.00** → Save. Open the price and copy its ID (`price_…`). On github.com, edit
   `cloudflare/wrangler.jsonc` and put it in the **staging** section's `"STRIPE_PRICE_ID": ""`.
3. **Developers → Webhooks → Add destination** (or "Add endpoint"):
   - Endpoint URL: `https://staging.misscleary.com/api/billing/webhook`
   - Events: `checkout.session.completed`, `customer.subscription.created`,
     `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.paid`, `invoice.payment_failed`
   - Then copy its **Signing secret** (`whsec_…`) → staging secret `STRIPE_WEBHOOK_SECRET`.
4. **Developers → API keys** → **Secret key** (`sk_test_…`) → staging secret `STRIPE_SECRET_KEY`.
5. **Settings → Billing → Customer portal** → **Activate** (lets teachers cancel or change card themselves).

### 2.5 Try it all on staging

Once you've saved `wrangler.jsonc` on GitHub, run **Actions → Build and deploy → Run workflow →
staging** again so it picks up the price ID. Then:

1. https://staging.misscleary.com/teachers → sign in with Google, and try Microsoft too.
2. **Subscribe** → card `4242 4242 4242 4242`, any future date, any CVC, any postcode.
3. Back on the teachers page: **Active**. **Add class** → copy the link.
4. Open the link in a private/incognito window: the game should open, as a student would see it.
5. **Manage billing** → cancel. Students lose access on their next visit once it ends.

---

# Part 3: switching features on and off

On github.com, open `cloudflare/wrangler.jsonc` → pencil icon → change `"off"` to `"on"` (or back)
in the **top** section for the real site → **Commit changes** (to `main`). It republishes in ~3 minutes.

To set up the real site, add the same secrets to the **lesson-island** Worker (step 2's intro,
but the other Worker). For real payments, use Stripe in **live mode** with its own price, webhook
(`https://misscleary.com/api/billing/webhook`) and `sk_live_…` key. Stripe asks for your
business details before live payments work.

Other settings in `wrangler.jsonc`:
- `COMPLIMENTARY_EMAILS`: teachers who get a free plan, e.g. your wife's colleagues during the beta.
- `ADMIN_EMAILS`: who can use the editor when `FEATURE_PROTECT_EDITOR` is on.
- `STRIPE_TRIAL_DAYS`: free trial for new subscribers (`"0"` = none).
- `STRIPE_AUTOMATIC_TAX`: `"on"` once you're VAT-registered and have set up Stripe Tax.
- Promotion codes made in Stripe (e.g. 3 months free) can be typed in at checkout.

**Before switching sign-in or payments on for the real site:** you'll want a short privacy
notice page (what's stored: teachers' name, email and subscription; nothing about students), and,
for payments, terms. Schools will ask.

---

## For later / reference

**Costs** (free tiers, November 2026): Workers 100,000 requests/day (a game load is ~15, so roughly
6,000 plays a day); R2 10 GB; D1 5 GB. Stripe takes about 1.5% + 20p per UK card payment (≈25p of £3).

**Running it on your own computer** (optional, needs [Node.js](https://nodejs.org)): export from Godot
into `build/web`, then in `cloudflare/`: `npm install`, `npm run dev` → http://localhost:8787.
`npm test` runs the quick checks. `npm run deploy` publishes from your computer instead of GitHub
(after `npx wrangler login`).

**Files**
- `wrangler.jsonc`: switches, settings, live and staging sites, domain
- `../.github/workflows/deploy.yml`: the GitHub build-and-publish steps (Godot version is set here)
- `src/flags.js`: how the switches combine
- `src/index.js`: routing, `www` → plain domain, serving the big files from R2
- `src/auth.js`: Google and Microsoft sign-in (OpenID Connect + PKCE)
- `src/billing.js`: Stripe checkout, customer portal, webhook
- `src/classes.js`, `src/access.js`: classes, join codes, and the gate in front of the game
- `src/pages/`: the `/teachers` and `/join` pages
- `migrations/`: database tables (applied automatically on each publish)
- `../tools/prepare_site.mjs`: copies config/lessons/editor next to the game, moves big files aside
