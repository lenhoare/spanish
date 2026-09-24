# Lesson Island (currently configured as "La Isla del Saber")

A cute 3D island adventure for phones and desktop browsers, built in Godot 4.6 with
Kenney assets. `config.json` sets the game's name, the hero names and the list of islands;
each island is one lesson file (see `LESSON_FORMAT.md`). The current course is six Year 9
Spanish islands in `lessons/spanish/`, made from `lessons/spanish_grammar_and_vocabulary_complete.md`.

**The loop:** explore, jump and collect stars (fun on its own) -> find question cards ->
answer them to rebuild the bridge -> reach Star Island and claim the prize. Stuck? Jump at
the whiteboard in the middle of the island to read the lesson; wrong answers lock a
question until you've read it.

## Controls
- Desktop: WASD/arrows to move, Space to jump (twice = double jump), drag the mouse or Q/E to look, scroll to zoom.
- Whiteboard: jump at it to open; arrow keys turn pages, Esc closes.
- Phone (landscape): left thumb anywhere = joystick, JUMP button bottom-right, drag with the right thumb to look.

## Project layout
- `config.json`: game name, heroes, island list, text size, accent strictness
- `lessons/spanish/*.json`: the six Spanish islands
- `scripts/main.gd`: game flow (title -> island picker -> play -> prize)
- `scripts/world.gd`: the island level template, its card/chest slots and colour themes
- `scripts/ui.gd`: title screen, island picker, HUD, whiteboard viewer, question cards, results
- `scripts/markdown.gd`: Markdown -> Godot BBCode (split into blocks for paging)
- `scripts/lesson_loader.gd`: loads config and lessons (from the web server, or the bundled copies)
- `assets/fonts/fredoka.ttf`: UI font (SIL Open Font License, see `OFL-fredoka.txt`)

## Build the web version
```
C:\godot\4.6\Godot_v4.6.2-stable_win64_console.exe --headless --path . --export-release "Web" build/web/index.html
```
Then copy `config.json` and the `lessons` folder into `build/web/` (keeping the folder structure),
and upload everything in `build/web/` to any static host (GitHub Pages, Netlify, Cloudflare Pages).
To change lessons or islands later, just edit `config.json` / the lesson files on the server - no rebuild.

## Test on your phone at home
Godot web games need HTTPS (or localhost), so use the HTTPS test server:
```
python tools\serve_https.py
```
Then open `https://<this-PC's-IP>:8443` on a phone on the same Wi-Fi. The first time, the phone
warns the connection "isn't private" (the certificate is home-made): Android - Advanced -> Proceed;
iPhone - Show Details -> visit this website. Allow Python through the Windows firewall if asked.
Real hosting (GitHub Pages, Netlify, Cloudflare Pages) gives proper HTTPS with no warning.

## Dev tools
- `godot --path . -- --autotest` plays through the game and saves screenshots to
  `%APPDATA%\Godot\app_userdata\Lesson Island\shots` (add `--phone --touch` with `--resolution 844x390` for a phone layout pass).
- `godot --path . -- --islandshots` visits every island and screenshots it.
- `node tools/webtest.mjs http://localhost:8060/index.html <outdir> [phone]` smoke-tests the web build in headless Chrome
  (only ever one test Chrome; it is always closed afterwards).
