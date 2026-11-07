# Adding a Teacher Game to mscleary.com

Each teacher game lives in **its own GitHub repository** and publishes itself to
**mscleary.com/games/<name>/**. The Teacher Games page (**mscleary.com/games/**) lists them, and
the game's "Teacher Games" button opens that page.

Games can be **HTML** (files in a `public/` folder) or **Godot 4.6.2** projects. The same
publish workflow handles both.

```
 github.com/lenhoare/battleships   ──push──►  GitHub Actions  ──►  R2 storage: games/battleships/
                                                                         │
 mscleary.com/games/battleships/   ◄──────── the site's Worker ◄─────────┘
 mscleary.com/games/               ◄──────── card in web/games/games.json (spanish repository)
```

Because the games are served by the same site, its switches cover them too: if class codes are
switched on (`FEATURE_REQUIRE_ACCESS`), the games page and every game need a code or a teacher
sign-in, just like the islands.

---

## One-time setup: a storage key for publishing games (≈5 min)

All games share one key that can **only** write to the site's R2 storage bucket.

1. Cloudflare dashboard → **R2 object storage** (direct link:
   https://dash.cloudflare.com/?to=/:account/r2) → **Manage API tokens** (or **API** → **Manage API tokens**).
2. **Create Account API token** (or "Create API token"):
   - **Name:** `Publish teacher games`
   - **Permissions:** **Object Read & Write**
   - **Specify bucket(s):** **Apply to specific buckets only** → `lesson-island-files`
   - **TTL:** forever (or a date you'll remember to renew)
3. **Create**, then copy these two (shown once), into a temporary note:
   - **Access Key ID**
   - **Secret Access Key**

   (Ignore the "Token value" and the endpoint; the workflow builds the endpoint itself.)

You'll also need your **Cloudflare Account ID** (the same one as in the spanish repository's secrets).

---

## For each new game (≈10 min)

1. **Make a repository** on GitHub: e.g. `battleships`. Private is fine. The repository name
   becomes the address (`mscleary.com/games/battleships/`): lowercase, hyphens for spaces.
   (To use a different address, add a repository *variable* `GAME_ID`.)
2. **Add the game:**
   - HTML game: put its files in a folder called **`public/`**, with the start page at
     `public/index.html`.
   - Godot game: the Godot project at the top of the repository, with an export preset called
     **`Web`** (thread support off).
3. **Add the two files from this folder:**
   - `publish.yml` → in the game repository as **`.github/workflows/publish.yml`**
   - `CLAUDE.template.md` → in the root of the game repository, **renamed to `CLAUDE.md`**.
     Replace `GAME_ID` in it with the game's name (e.g. `battleships`). Claude Code reads this file automatically, so any future session
     on the game knows how it must be built to work on mscleary.com.
4. **Add three secrets** to the game repository (**Settings → Secrets and variables → Actions →
   New repository secret**):

   | Name | Value |
   |---|---|
   | `R2_ACCESS_KEY_ID` | Access Key ID from the one-time setup |
   | `R2_SECRET_ACCESS_KEY` | Secret Access Key from the one-time setup |
   | `CLOUDFLARE_ACCOUNT_ID` | your Cloudflare account ID |

5. **Push to `main`** (or **Actions → Publish game → Run workflow**). When it's green, the game is
   at `https://mscleary.com/games/<name>/` and `https://staging.mscleary.com/games/<name>/`.
6. **Add its card** to the Teacher Games page: in the **spanish** repository, edit
   `web/games/games.json`:

   ```json
   {
     "games": [
       {
         "id": "battleships",
         "title": "Batalla naval",
         "description": "Sink your opponent's fleet by answering questions.",
         "emoji": "🚢",
         "color": "#2e86de"
       }
     ]
   }
   ```

   - `id` must match the address (`mscleary.com/games/battleships/`).
   - Optional: `"image": "/games/battleships/card.png"` instead of an emoji; `"url"` for a game
     hosted somewhere else; `"hidden": true` to take a card off the page without deleting it.

   Merge that change and the card appears about a minute later.
7. **First game only:** point the "Teacher Games" button at the page. In the spanish repository's
   **`games.json`** (the one at the top level, not the one in `web/games/`), set
   `"teacher_games": "/games/"`. Until then the button keeps saying "Coming soon!".

## Updating and removing games

- **Update:** push to the game's repository; it republishes itself. Files you delete from the
  game are removed from the site too.
- **Remove:** set `"hidden": true` (or delete its card) in `web/games/games.json`. To delete its
  files as well: Cloudflare → R2 → `lesson-island-files` → folder `games/<name>/` → delete.
