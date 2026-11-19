# Soul Keeper — Project Plan

## 1. What it is
A mobile-first app for Afghan women, inside Afghanistan and abroad, that addresses the gradual loss of hope, motivation and personal dreams caused by difficult circumstances, restrictions, displacement and lack of opportunity. Instead of writing dreams down, the user builds a **visual world** of the future she imagines (her home, surroundings, career, education, art, nature) and returns to it over time.

A serious project intended for eventual public launch, built step by step with AI-assisted tools on a limited budget.

## 2. Target users
Afghan women inside Afghanistan and abroad. Some may be in restrictive or unsafe situations, so **privacy and discretion are essential**.

## 3. Tech stack
**Godot 4.4.1** with GDScript and the *GL Compatibility* renderer (required for web). Chosen over Flutter (better for forms and lists, not exploration) and Unity (steeper learning curve, C#, heavier).

## 4. Platform
- **Phase 1: Web.** HTML5/WebAssembly build without threads, so it runs on any static host with no special server headers.
- **Later:** Android and iOS from the same project.

## 5. Privacy & discretion
- Generic name and icon: **"Garden" / «باغ من» / «زما باغ»** with a leaf icon *(done; shown in the browser tab and on the title screen)*.
- Search engines are told not to index the web build (`noindex`) *(done)*.
- Data stays on the device: no server, no accounts, no analytics *(done)*.
- Works fully offline from the first visit (service worker caches the whole game) *(done)*.
- Installable as "Garden" with a leaf icon *(done)*.
- Optional 4-digit PIN, salted hash only; auto-lock when the app is backgrounded *(done)*.
- Quick-hide leaf button / Esc → neutral "Garden notes" cover screen *(done)*.
- Forgot PIN → start over (erases the world) *(done)*.

## 6. Languages
Dari (default) · Pashto · English. They're modular, so adding a language means adding a JSON file. **The Dari and Pashto text needs native-speaker review.**

## 7. Visual style
Calm, hopeful, game-like **3D** in a soft low-poly style (a small floating "diorama" world seen from a gentle angle). Everything is built in code from simple shapes with real lighting, soft shadows and moving water, kept in a few files so real 3D models can replace it later.

## 8. MVP features
Customisable avatar · explorable dream world · home exterior and interior · garden surroundings · a self-chosen workplace that she can enter · local save and return.
**Deferred:** goal tracking, journaling, AI guide.

## 9. Phases

| Phase | Scope | Status |
|---|---|---|
| 0: Setup & skeleton | Project, folders, modular localisation (fa_AF/ps/en), RTL | ✅ Done |
| 1: One location end-to-end in browser | Avatar, home exterior + interior, movement (tap + keys), local save/load on PWA-friendly storage, web export | ✅ Done |
| 2: Expand the world | Garden ✅ · workplace plot with 6 choices, each enterable ✅ · town with market and fountain ✅ · university ✅ · library ✅ · mountain view with river ✅ · decorating her garden, home and workplace (place, move, recolour, remove) ✅ | ✅ Done |
| 3: Privacy & discretion | PWA manifest + icons + "Add to Home Screen" ✅ · offline from first visit ✅ · PIN ✅ · auto-lock ✅ · quick-hide cover screen ✅ | ✅ Done |
| 4: Polish & real-world testing | Share link, gather feedback, iterate; real art when funded | ⬜ |

## 10. Decisions log
1. Engine: Godot (over Flutter and Unity).
2. Platform: web first; mobile exports later from the same project.
3. Art: placeholders now (soft geometric, drawn in code), real art once funded.
4. Storage: `user://` (IndexedDB on web) from Phase 1, with persistent-storage request and a backup file; PWA polish in Phase 3.
5. *(Session 2)* Perspective: **isometric 2.5D**.
6. *(Session 2)* Placeholder style: **soft geometric shapes**.
7. *(Session 2)* Workplace: **she chooses** what to build on an empty plot: art studio, school, clinic, office, shop, or tailoring workshop. More types can be added as data.
8. *(Session 2)* Repository: private GitHub repo `soul-keeper`.
9. *(Session 2)* Mobile-first base resolution 480×600 that stretches to fit; works in portrait and landscape.
10. *(Session 2)* Font: Vazirmatn (open licence), covering Dari, Pashto and Latin, because web builds can't use system fonts.

11. *(Session 3)* New places: town (market, fountain) → university and library interiors; mountain view with a river and bridge. Reached through garden-style gates.
12. *(Session 3)* PIN: optional, 4 digits, salted SHA-256 in the local save, no lockout after wrong tries (avoids locking people out); "Forgot PIN" = start over.
13. *(Session 3)* Quick-hide shows neutral gardening tips that match the "Garden" cover name; tapping its leaf returns (through the PIN if set).
14. *(Session 3)* Offline: Godot's service worker patched to cache the whole game on first visit (~45 MB).

15. *(Session 4)* Decorating only in her own spaces (garden, home, workplace); public places stay fixed. Picture-only tray, no words. Each workplace type keeps its own decorations. Max 60 items per place. Built-in furniture stays fixed; only what she places can be moved.
16. *(Session 4)* Automated tests (`tests/run_tests.gd`) run in CI before every web build.

17. *(Session 4)* Sound: generated placeholder music/ambience/effects (no licences). On by default but quiet; on/off switch on the title screen and in the Menu; silenced instantly by quick-hide and auto-lock; the hide button itself never makes a sound.

18. *(Session 5)* **Moved from 2D to 3D** at the user's request. Built in code (free CC0 model packs reachable from here had no furniture or suitable character, and mixing styles looked patchy). Same data, saves, rules and UI underneath. Real-time shadow maps off (WebGL washed out colours); soft shadows drawn instead. Custom lighting shader so brightness is the same on every device.
19. *(Session 5)* Sound button moved to the top bar (speaker icon), and the title screen.

## 11. Open questions
- Who can review the Dari and Pashto text?
- Should she also be able to move or remove the built-in furniture, not just what she adds?
- What should the next Phase 2 places be (e.g. university, city street, mountains or the countryside)?
- Hosting for test links: itch.io (restricted page) or Netlify?
- Should the saved world be encrypted with the PIN (stronger protection, but a forgotten PIN then loses everything for certain)?
- Is ~45 MB first download acceptable on users' data plans? (Godot's engine is most of it; a smaller custom engine build is possible later.)
- How smooth is the 3D on the testers' actual phones (especially older Android)? If slow, options: fewer grass tufts, lower resolution, or a "simple graphics" switch.
- Should she be able to turn the camera around her world (two-finger drag), or keep the fixed gentle angle?
- Should sound start **off** by default for safety, with women turning it on themselves? (Currently on, quietly.)
- Real music later: a local musician (e.g. rubab or santur) would make it feel like home.
- Should quick-hide also trigger from a gesture (e.g. shaking the phone, or a two-finger tap)?
