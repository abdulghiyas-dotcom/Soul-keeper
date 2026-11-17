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
- Works offline once loaded; full offline install via a service worker *(Phase 3)*.
- Simple PIN *(Phase 3)*.

## 6. Languages
Dari (default) · Pashto · English. They're modular, so adding a language means adding a JSON file. **The Dari and Pashto text needs native-speaker review.**

## 7. Visual style
Calm, hopeful, game-like **isometric 2.5D**. Placeholder art is soft geometric shapes drawn in code, kept in a few files so real art can replace it later.

## 8. MVP features
Customisable avatar · explorable dream world · home exterior and interior · garden surroundings · a self-chosen workplace that she can enter · local save and return.
**Deferred:** goal tracking, journaling, AI guide.

## 9. Phases

| Phase | Scope | Status |
|---|---|---|
| 0: Setup & skeleton | Project, folders, modular localisation (fa_AF/ps/en), RTL | ✅ Done |
| 1: One location end-to-end in browser | Avatar, home exterior + interior, movement (tap + keys), local save/load on PWA-friendly storage, web export | ✅ Done |
| 2: Expand the world | Garden ✅ · workplace plot with 6 choices, each enterable ✅ · more places (school/university campus, city street, mountains?) ⬜ | 🟡 Started |
| 3: Privacy & discretion | PWA manifest + icon + "Add to Home Screen", service-worker offline cache, simple PIN, quick-hide | ⬜ |
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

## 11. Open questions
- Who can review the Dari and Pashto text?
- Should she be able to place and move items herself (trees, furniture) in Phase 2, or keep the world pre-arranged for now?
- What should the next Phase 2 places be (e.g. university, city street, mountains or the countryside)?
- Hosting for test links: itch.io (restricted page) or Netlify?
- PIN behaviour: what happens after a forgotten PIN, given that there's no account to recover with?
- Should there be a quick-hide gesture or button that instantly shows a neutral screen?
