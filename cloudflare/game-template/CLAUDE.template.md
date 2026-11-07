# CLAUDE.md: a game for mscleary.com
<!-- Template: copy into a game repository as CLAUDE.md and replace every GAME_ID (see README.md). -->

This repository is **one game** on Ms Cleary's Spanish site. It's published automatically to
**https://mscleary.com/games/GAME_ID/** (and staging.mscleary.com) by `.github/workflows/publish.yml`
on every push to `main`. The site, its Teacher Games page and the other games live in other
repositories; don't try to change them from here.

## How the game must be built

**HTML game** (no `project.godot`): everything the browser needs goes in `public/`, with the start
page at `public/index.html`. Plain HTML, CSS and JavaScript, with no build step. If a build tool is
ever added, its output must end up in `public/`.

**Godot game** (`project.godot` in the repository root): Godot **4.6.2**, **GL Compatibility**
renderer, an export preset named exactly **`Web`** with **thread support off**. The workflow runs
`--import` and then `--export-release "Web"`, so don't commit the `.godot/` folder.

## Rules for living on a shared website

The game is served from a sub-folder (`/games/GAME_ID/`) on the same site as other games:

- **Relative links only.** Use `img/ship.png` or `./sounds/hit.mp3`, never `/img/ship.png`
  (a leading `/` points at the main site, not this game).
- **Saved data is shared between all games on mscleary.com**, so namespace it:
  - `localStorage` / `sessionStorage` keys start with `GAME_ID:` (e.g. `battleships:scores`).
  - Godot: `user://` is the *same folder* for every Godot game on the site. Save under
    `user://GAME_ID/` (e.g. `user://battleships/settings.json`), never just `user://progress.json`.
- Don't use cookies, and never touch the site's own `/api/`, `/auth/`, `/teachers` or `/join` pages.
- **No personal data, no analytics, no trackers, no adverts.** The site's privacy notice promises
  students that. Prefer local copies of fonts and libraries over external CDNs (school web filters
  often block them, and they'd see students' IP addresses).

## Who plays it, and on what

Teacher games are often played **at the front of the class**: projector, interactive whiteboard,
or a school laptop, sometimes a tablet or phone.

- Big, readable text and buttons, high contrast; looks right from the back of a classroom.
- Works with **mouse, touch and keyboard**, and at any screen size (landscape first).
- Starts fast on modest school hardware. Keep downloads small; Godot games especially should
  avoid heavy particles and post-processing.
- Spanish text must handle accents (á é í ó ú ñ ü ¿ ¡) everywhere.

## Testing

- HTML: open `public/index.html`, or better serve it (`python -m http.server --directory public`) and
  visit http://localhost:8000. Check it also works from a sub-folder (relative links!).
- Godot: run in the editor; for the web build, export to a folder and serve it the same way.
- After publishing, check https://mscleary.com/games/GAME_ID/ (refresh fully).
