# CLAUDE OPUS / CLAUDE CODE — LOST FREQUENCY: 100 CANON-LOCKED BACKROOMS LEVELS, WITHOUT QUALITY COLLAPSE

**FULL IMPLEMENTATION MANDATE — self-contained / Godot 4 project / source-backed / production QA**

Date of mandate: 2026-11-04. Starting asset: the user's `LOST_FREQUENCY_V62_FULL.zip` Godot project, or its latest verified descendant. This document supersedes any previous instructions that capped the project at 18 playable levels. It preserves and strengthens the previous continuity lock. This is not a request to merely draft ideas: **audit, implement, run, test, document, commit, and package actual improvements**. Do not create a cosmetically impressive 100-level menu filled with generic empty boxes.

## 0. Non-negotiable customer requirements

1. Deliver a **target of exactly 100 distinct, playable, lore-accurate Backrooms destinations**, counted from the numbered/sublevel roster later in this document. The Hub and debug sandbox do not count toward the 100, and no two entries can secretly be the same map under different names.
2. **Popular and visually/mechanically distinctive levels must be the production priority**, not arbitrary Level 0–99 numerical order. Draw priority evidence from the chosen wiki's `Top Rated Pages` and `Top Rated Pages By Year`, supplemented by clearly labeled community demand; do not confuse ranking scores with objective popularity across all Backrooms fandoms.
3. The game must remain a **Backrooms adaptation, not a Minecraft clone, GMod map collection, or generic survival-horror theme park**. The user uses “Minecraft standards” to demand density, traversal, discovery, scale and replayability—not block graphics, voxel digging, mobs everywhere or a mandatory crafting system.
4. Every level must honor the **exact selected Wikidot page's environmental identity, rules, hazards, light, entities, items, entry and exit conditions**. The atmosphere can be sophisticated and realistic without mixing distinct canon families.
5. Every level must be a **real space to explore**. Not a one-room test scene, disconnected gallery, 48 m repeated tile grid, or photograph/skybox disguised as an environment. Exception: where a canonical page intentionally describes a compact room or nearly empty world, fidelity overrides artificial room count; build its actual phenomenon, events, interaction and exit logic instead.
6. Every level must pass **engine-executed playability and quality verification**, not simply Python tests or project.godot parsing. The release cannot claim "100 fully playable" until each of the 100 passes its own complete acceptance checklist.
7. The user's access pain is P0: **Esc must open a working mouse-interactive pause menu, F3 must allow direct level selection in a separate developer mode, and gameplay transitions must be discoverable in a lore-compatible way**. Debug cheats cannot silently contaminate a canonical story playthrough or replace real exits.
8. **Verticality must be meaningful and lore-appropriate:** multilayer caves/shafts, underwater depth, traversable hotel floors and urban interiors, atria, balconies and service spaces where the source warrants them. Never mechanically require a tall tower inside a level whose canonical identity is a one-room illusion, open field, darkness or single apartment.
9. Full release and online publication require careful **attribution, Creative Commons licensing and independent asset rights review**. No scraping copyrighted game models/music/photos and calling that “industrial quality.”
10. **Preserve evidence and implementation work in the repository.** For each batch, produce committed code, actual scenes, tests, screenshots, performance reports, lore citations and clean release packaging. Do not commit bulky failed experiments or redundant binary logs.

## 1. Source-of-truth and canon policy — this is a hard release gate

Reference continuity: **English Backrooms Wikidot, https://backrooms-wiki.wikidot.com/**. This is a **project-selected continuity**, not the one universally official Backrooms canon. Use the currently live page specific to the ID, *not* titles/descriptions from Fandom, Kane Pixels, YouTube, alternative Wikidot canons, or older wiki snapshots unless the user explicitly authorizes a parallel canon module. Source facts must be dated, attributable and revisitable.

Primary directories and evidence:
- https://backrooms-wiki.wikidot.com/normal-levels-i
- https://backrooms-wiki.wikidot.com/top-rated-pages
- https://backrooms-wiki.wikidot.com/top-rated-pages-by-year
- https://backrooms-wiki.wikidot.com/unnumbered-levels
- https://backrooms-wiki.wikidot.com/licensing-guide
- https://backrooms-wiki.wikidot.com/image-use-policy

**IMPORTANT:** The roster below is a *curated development target*, **not** a claim that all 100 source URLs, working titles, exact lore or current page revisions were individually reverified in this mandate. Its verified basis includes sampled pages and the wiki's live top-rated lists. Opus MUST open all 100 live URLs, handle missing/renamed/revised entries, capture the actual article titles, authors and revision/observation dates, and mark any incorrect candidate. Never hallucinate a canonical page to satisfy a number.

Example of a version mismatch: at the chosen Wikidot, **Level 94 is “Motion”**, not a title imported from another wiki. **Level 974 “Kitty's House”** is a finite pink home with entity-specific exit rules and must not be inflated into a monster-ridden mansion maze. **Level 601 “The End”** is a numbered Wikidot entry; do not blindly equate it with other wikis' unnumbered “The End.” **Level 0.1 “Zenith Station”** is a complex nested sublevel rather than interchangeable yellow wallpaper. Each is a demonstration of why the source page must be read, not guessed.

Before implementing any level, create and approve:
- `docs/canon/CANON_POLICY.md`: continuity selection, citation rules, exceptions, Fandom/Kane/legacy separation.
- `docs/canon/LEVEL_100_MATRIX.csv`: 100 source-linked entries, current title, author, revision/access date, physical identity, anomalies, lighting/sound, known/rumored entities, hazard, items/communities, entrances, exits, license, source confidence, content status, implementation status, QA status, conflicts.
- `docs/canon/levels/<stable_id>.md`: **SOURCE FACT → SPECIFIC IN-GAME IMPLEMENTATION → TEST EVIDENCE**, with links to exact sections or relevant quotes (short, correctly attributed).
- `docs/canon/CONFLICTS_AND_REWRITES.md`: existing V62 errors, new ambiguities, canonical restrictions and resolution decisions; block content with unresolved critical lore conflict.
- `data/canon/levels.json`: stable IDs and source metadata; `data/canon/transitions.json`: rigorously sourced directed edges and triggers, with developer-only edges stored separately.
- `docs/canon/ATTRIBUTION_AND_LICENSES.md` and `assets/ASSET_PROVENANCE.csv` for page authors, media authors, licenses, URLs, assets created in-project, and any prohibited third-party material.

The Backrooms Wiki's licensing guide states its contributions are under **CC BY-SA 3.0** and gives specific advice for derivative games, redistribution, attribution, DRM and code licensing. Treat that guide as a compliance requirement, but obtain actual review if the project is distributed commercially. Ensure the repository and distribution license matches the chosen adaptation/derivative strategy. Do not blindly relicense incompatible third-party assets.

### Prohibited canon errors

- Level 7 is not an archive; Level 11 is not just a metro station; Level 12 is not an industrial hangar; Level 13 is not a greenhouse; Level 14 is not a duct maze.
- Do not add wandering combat NPCs/entities to Level 0, Level 6 or Level 37 where incompatible with the selected entries. In particular, Level 37 has an important *absence* of inhabitants in its reference account.
- Do not make every window of Level 188 an easy level-select portal. Do not ignore window-specific risk.
- Do not turn “Level ! / RUN FOR YOUR LIFE”, “Level Fun”, or “Level 3999” from other lore branches into entries in the numbered Wikidot roster without locating an exact matching source on the selected site. They may become separately marked **alternative-continuity modules** only after explicit authorization, and they do not secretly count toward the source-locked 100.
- Do not simplify every documented entrance into `F4 = Level N+1` or route every world through an invented universal teleporter. Developer jump controls are allowed exclusively in developer mode.
- Do not force combat, a side quest, an entity, a collectible or five storeys into every level. Lore-appropriate emptiness, solitude and false reassurance are valid design outcomes, but must be intentional and high quality rather than unfinished content.

## 2. Exactly 100 curated destinations — fixed-count baseline

**Preserve all 18 existing level IDs, add the 82 entries in the remaining three groups, and do not double count subdivisions, hub spaces or menu-only previews.** The list totals **18 + 32 + 25 + 25 = 100** unique IDs; a machine-readable copy is included as `BACKROOMS_100_LEVEL_ROSTER.csv` when delivered alongside this mandate. The four groups are a production plan, not an assertion that every candidate is equally popular. All groups have the same final acceptance criteria.

### GROUP A — the 18 existing V62 level identities (all must be corrected and retained)

Migrate, re-audit, and bring each to the new quality bar; V62 having a named scene does not mean it counts as complete.

| Slot | Level ID | Working article title / placeholder | Candidate source (verify) |
|---:|---|---|---|
| 001 | Level 0 | Threshold | [https://backrooms-wiki.wikidot.com/level-0](https://backrooms-wiki.wikidot.com/level-0) |
| 002 | Level 1 | Habitable Zone | [https://backrooms-wiki.wikidot.com/level-1](https://backrooms-wiki.wikidot.com/level-1) |
| 003 | Level 2 | Abandoned Utility Halls | [https://backrooms-wiki.wikidot.com/level-2](https://backrooms-wiki.wikidot.com/level-2) |
| 004 | Level 3 | Electrical Station | [https://backrooms-wiki.wikidot.com/level-3](https://backrooms-wiki.wikidot.com/level-3) |
| 005 | Level 4 | Abandoned Office | [https://backrooms-wiki.wikidot.com/level-4](https://backrooms-wiki.wikidot.com/level-4) |
| 006 | Level 5 | Terror Hotel | [https://backrooms-wiki.wikidot.com/level-5](https://backrooms-wiki.wikidot.com/level-5) |
| 007 | Level 6 | Lights Out | [https://backrooms-wiki.wikidot.com/level-6](https://backrooms-wiki.wikidot.com/level-6) |
| 008 | Level 7 | Thalassophobia | [https://backrooms-wiki.wikidot.com/level-7](https://backrooms-wiki.wikidot.com/level-7) |
| 009 | Level 8 | Cave Systems | [https://backrooms-wiki.wikidot.com/level-8](https://backrooms-wiki.wikidot.com/level-8) |
| 010 | Level 9 | The Suburbs | [https://backrooms-wiki.wikidot.com/level-9](https://backrooms-wiki.wikidot.com/level-9) |
| 011 | Level 10 | Bumper Crop | [https://backrooms-wiki.wikidot.com/level-10](https://backrooms-wiki.wikidot.com/level-10) |
| 012 | Level 11 | The City That Never Sleeps | [https://backrooms-wiki.wikidot.com/level-11](https://backrooms-wiki.wikidot.com/level-11) |
| 013 | Level 12 | Matrix | [https://backrooms-wiki.wikidot.com/level-12](https://backrooms-wiki.wikidot.com/level-12) |
| 014 | Level 13 | The Boiling Frogs | [https://backrooms-wiki.wikidot.com/level-13](https://backrooms-wiki.wikidot.com/level-13) |
| 015 | Level 14 | Paradise | [https://backrooms-wiki.wikidot.com/level-14](https://backrooms-wiki.wikidot.com/level-14) |
| 016 | Level 19 | Attic Floorboards | [https://backrooms-wiki.wikidot.com/level-19](https://backrooms-wiki.wikidot.com/level-19) |
| 017 | Level 37 | Sublimity | [https://backrooms-wiki.wikidot.com/level-37](https://backrooms-wiki.wikidot.com/level-37) |
| 018 | Level 188 | The Courtyard of Windows | [https://backrooms-wiki.wikidot.com/level-188](https://backrooms-wiki.wikidot.com/level-188) |

### GROUP B — 32 high-priority popular and distinctive numbered levels

Flagship candidates. Many have a demonstrable place in the Wikidot top-rated/year lists; prioritize lore fit and breadth.

| Slot | Level ID | Working article title / placeholder | Candidate source (verify) |
|---:|---|---|---|
| 019 | Level 15 | Futuristic Halls | [https://backrooms-wiki.wikidot.com/level-15](https://backrooms-wiki.wikidot.com/level-15) |
| 020 | Level 16 | Altered Topography | [https://backrooms-wiki.wikidot.com/level-16](https://backrooms-wiki.wikidot.com/level-16) |
| 021 | Level 17 | The Carrier | [https://backrooms-wiki.wikidot.com/level-17](https://backrooms-wiki.wikidot.com/level-17) |
| 022 | Level 18 | Memories | [https://backrooms-wiki.wikidot.com/level-18](https://backrooms-wiki.wikidot.com/level-18) |
| 023 | Level 20 | Boreas Structure | [https://backrooms-wiki.wikidot.com/level-20](https://backrooms-wiki.wikidot.com/level-20) |
| 024 | Level 22 | Ruins Left Behind | [https://backrooms-wiki.wikidot.com/level-22](https://backrooms-wiki.wikidot.com/level-22) |
| 025 | Level 23 | The Petrified Garden | [https://backrooms-wiki.wikidot.com/level-23](https://backrooms-wiki.wikidot.com/level-23) |
| 026 | Level 24 | The Moon | [https://backrooms-wiki.wikidot.com/level-24](https://backrooms-wiki.wikidot.com/level-24) |
| 027 | Level 25 | The Quarter Hub | [https://backrooms-wiki.wikidot.com/level-25](https://backrooms-wiki.wikidot.com/level-25) |
| 028 | Level 26 | The SS Fun =) | [https://backrooms-wiki.wikidot.com/level-26](https://backrooms-wiki.wikidot.com/level-26) |
| 029 | Level 27 | The Bunker Springs | [https://backrooms-wiki.wikidot.com/level-27](https://backrooms-wiki.wikidot.com/level-27) |
| 030 | Level 28 | Final Virtue | [https://backrooms-wiki.wikidot.com/level-28](https://backrooms-wiki.wikidot.com/level-28) |
| 031 | Level 29 | Hyperian | [https://backrooms-wiki.wikidot.com/level-29](https://backrooms-wiki.wikidot.com/level-29) |
| 032 | Level 30 | Shifted Beyond Reality | [https://backrooms-wiki.wikidot.com/level-30](https://backrooms-wiki.wikidot.com/level-30) |
| 033 | Level 31 | The Roller Rink | [https://backrooms-wiki.wikidot.com/level-31](https://backrooms-wiki.wikidot.com/level-31) |
| 034 | Level 36 | Timeless Airport | [https://backrooms-wiki.wikidot.com/level-36](https://backrooms-wiki.wikidot.com/level-36) |
| 035 | Level 48 | The Sunset Beach | [https://backrooms-wiki.wikidot.com/level-48](https://backrooms-wiki.wikidot.com/level-48) |
| 036 | Level 49 | The Unfilled River of Phlegethon | [https://backrooms-wiki.wikidot.com/level-49](https://backrooms-wiki.wikidot.com/level-49) |
| 037 | Level 53 | Alone | [https://backrooms-wiki.wikidot.com/level-53](https://backrooms-wiki.wikidot.com/level-53) |
| 038 | Level 69 | The Road Trip of Affliction | [https://backrooms-wiki.wikidot.com/level-69](https://backrooms-wiki.wikidot.com/level-69) |
| 039 | Level 71 | Void Basement | [https://backrooms-wiki.wikidot.com/level-71](https://backrooms-wiki.wikidot.com/level-71) |
| 040 | Level 73 | The Redlands | [https://backrooms-wiki.wikidot.com/level-73](https://backrooms-wiki.wikidot.com/level-73) |
| 041 | Level 75 | Liminality | [https://backrooms-wiki.wikidot.com/level-75](https://backrooms-wiki.wikidot.com/level-75) |
| 042 | Level 79 | Ghosts in the Machine | [https://backrooms-wiki.wikidot.com/level-79](https://backrooms-wiki.wikidot.com/level-79) |
| 043 | Level 94 | Motion | [https://backrooms-wiki.wikidot.com/level-94](https://backrooms-wiki.wikidot.com/level-94) |
| 044 | Level 200 | Home | [https://backrooms-wiki.wikidot.com/level-200](https://backrooms-wiki.wikidot.com/level-200) |
| 045 | Level 256 | Demoscene | [https://backrooms-wiki.wikidot.com/level-256](https://backrooms-wiki.wikidot.com/level-256) |
| 046 | Level 289 | Overflow | [https://backrooms-wiki.wikidot.com/level-289](https://backrooms-wiki.wikidot.com/level-289) |
| 047 | Level 404 | my dearly fragmented | [https://backrooms-wiki.wikidot.com/level-404](https://backrooms-wiki.wikidot.com/level-404) |
| 048 | Level 601 | The End | [https://backrooms-wiki.wikidot.com/level-601](https://backrooms-wiki.wikidot.com/level-601) |
| 049 | Level 906 | The Cygnus Archive | [https://backrooms-wiki.wikidot.com/level-906](https://backrooms-wiki.wikidot.com/level-906) |
| 050 | Level 974 | Kitty's House | [https://backrooms-wiki.wikidot.com/level-974](https://backrooms-wiki.wikidot.com/level-974) |

### GROUP C — 25 strongly requested/high-rated sublevels and favorites

Sublevels count as a separate playable destination only if the source treats them as distinct and actually supports a full gameplay space.

| Slot | Level ID | Working article title / placeholder | Candidate source (verify) |
|---:|---|---|---|
| 051 | Level 0.1 | Zenith Station | [https://backrooms-wiki.wikidot.com/level-0-1](https://backrooms-wiki.wikidot.com/level-0-1) |
| 052 | Level 0.2 | Remodeled Mess | [https://backrooms-wiki.wikidot.com/level-0-2](https://backrooms-wiki.wikidot.com/level-0-2) |
| 053 | Level 0.3 | The Icy Rooms | [https://backrooms-wiki.wikidot.com/level-0-3](https://backrooms-wiki.wikidot.com/level-0-3) |
| 054 | Level 1.1 | Corrupted Corridor | [https://backrooms-wiki.wikidot.com/level-1-1](https://backrooms-wiki.wikidot.com/level-1-1) |
| 055 | Level 1.2 | Concrete Garden | [https://backrooms-wiki.wikidot.com/level-1-2](https://backrooms-wiki.wikidot.com/level-1-2) |
| 056 | Level 1.3 | Malignance | [https://backrooms-wiki.wikidot.com/level-1-3](https://backrooms-wiki.wikidot.com/level-1-3) |
| 057 | Level 1.5 | Inverted | [https://backrooms-wiki.wikidot.com/level-1-5](https://backrooms-wiki.wikidot.com/level-1-5) |
| 058 | Level 3.5 | Electropolis | [https://backrooms-wiki.wikidot.com/level-3-5](https://backrooms-wiki.wikidot.com/level-3-5) |
| 059 | Level 5.1 | Grand Opening of the Terror Hotel Casino | [https://backrooms-wiki.wikidot.com/level-5-1](https://backrooms-wiki.wikidot.com/level-5-1) |
| 060 | Level 6.1 | The Snackrooms | [https://backrooms-wiki.wikidot.com/level-6-1](https://backrooms-wiki.wikidot.com/level-6-1) |
| 061 | Level 7.7 | The Forsaken Debris | [https://backrooms-wiki.wikidot.com/level-7-7](https://backrooms-wiki.wikidot.com/level-7-7) |
| 062 | Level 10.1 | Corpse Lake | [https://backrooms-wiki.wikidot.com/level-10-1](https://backrooms-wiki.wikidot.com/level-10-1) |
| 063 | Level 11.3 | The Red Light District | [https://backrooms-wiki.wikidot.com/level-11-3](https://backrooms-wiki.wikidot.com/level-11-3) |
| 064 | Level 37.1 | The Sanguine Reservoir | [https://backrooms-wiki.wikidot.com/level-37-1](https://backrooms-wiki.wikidot.com/level-37-1) |
| 065 | Level 55 | Pit Stop | [https://backrooms-wiki.wikidot.com/level-55](https://backrooms-wiki.wikidot.com/level-55) |
| 066 | Level 58 | Water Wonder | [https://backrooms-wiki.wikidot.com/level-58](https://backrooms-wiki.wikidot.com/level-58) |
| 067 | Level 60 | The Baywalk | [https://backrooms-wiki.wikidot.com/level-60](https://backrooms-wiki.wikidot.com/level-60) |
| 068 | Level 83 | The Sunken Submarine | [https://backrooms-wiki.wikidot.com/level-83](https://backrooms-wiki.wikidot.com/level-83) |
| 069 | Level 90 | Newly Renovated Home | [https://backrooms-wiki.wikidot.com/level-90](https://backrooms-wiki.wikidot.com/level-90) |
| 070 | Level 96 | Solace | [https://backrooms-wiki.wikidot.com/level-96](https://backrooms-wiki.wikidot.com/level-96) |
| 071 | Level 808 | Synthwave World | [https://backrooms-wiki.wikidot.com/level-808](https://backrooms-wiki.wikidot.com/level-808) |
| 072 | Level 922 | Staircase / True End story (verify exact current title) | [https://backrooms-wiki.wikidot.com/level-922](https://backrooms-wiki.wikidot.com/level-922) |
| 073 | Level 965 | Colorful Colorless | [https://backrooms-wiki.wikidot.com/level-965](https://backrooms-wiki.wikidot.com/level-965) |
| 074 | Level 994 | Exist Here | [https://backrooms-wiki.wikidot.com/level-994](https://backrooms-wiki.wikidot.com/level-994) |
| 075 | Level 999 | [no subtitle on current page] | [https://backrooms-wiki.wikidot.com/level-999](https://backrooms-wiki.wikidot.com/level-999) |

### GROUP D — 25 further numbered/sublevel targets for content breadth

Additional candidate targets. The same lore, design and QA gate applies; no cheaper quality tier.

| Slot | Level ID | Working article title / placeholder | Candidate source (verify) |
|---:|---|---|---|
| 076 | Level 5.3 | Promethei Bibliotheca | [https://backrooms-wiki.wikidot.com/level-5-3](https://backrooms-wiki.wikidot.com/level-5-3) |
| 077 | Level 7.8 | Impaled Ocean | [https://backrooms-wiki.wikidot.com/level-7-8](https://backrooms-wiki.wikidot.com/level-7-8) |
| 078 | Level 9.3 | The Overcast Manifold | [https://backrooms-wiki.wikidot.com/level-9-3](https://backrooms-wiki.wikidot.com/level-9-3) |
| 079 | Level 11.2 | The Refuge | [https://backrooms-wiki.wikidot.com/level-11-2](https://backrooms-wiki.wikidot.com/level-11-2) |
| 080 | Level 21 | Numbered Doors | [https://backrooms-wiki.wikidot.com/level-21](https://backrooms-wiki.wikidot.com/level-21) |
| 081 | Level 32 | Forest of the Skeleton Queen | [https://backrooms-wiki.wikidot.com/level-32](https://backrooms-wiki.wikidot.com/level-32) |
| 082 | Level 41 | The Black Lake | [https://backrooms-wiki.wikidot.com/level-41](https://backrooms-wiki.wikidot.com/level-41) |
| 083 | Level 50 | The moribund Highway | [https://backrooms-wiki.wikidot.com/level-50](https://backrooms-wiki.wikidot.com/level-50) |
| 084 | Level 52 | DESTINATION REACHED | [https://backrooms-wiki.wikidot.com/level-52](https://backrooms-wiki.wikidot.com/level-52) |
| 085 | Level 77 | Oh, Shenandoah | [https://backrooms-wiki.wikidot.com/level-77](https://backrooms-wiki.wikidot.com/level-77) |
| 086 | Level 85 | Brilliant Evermore | [https://backrooms-wiki.wikidot.com/level-85](https://backrooms-wiki.wikidot.com/level-85) |
| 087 | Level 100 | Brief Peace | [https://backrooms-wiki.wikidot.com/level-100](https://backrooms-wiki.wikidot.com/level-100) |
| 088 | Level 101 | Your Dream Shall Never Dawn Again | [https://backrooms-wiki.wikidot.com/level-101](https://backrooms-wiki.wikidot.com/level-101) |
| 089 | Level 108 | Fertile Grounds | [https://backrooms-wiki.wikidot.com/level-108](https://backrooms-wiki.wikidot.com/level-108) |
| 090 | Level 114 | Sweet Dreams | [https://backrooms-wiki.wikidot.com/level-114](https://backrooms-wiki.wikidot.com/level-114) |
| 091 | Level 140 | Honey | [https://backrooms-wiki.wikidot.com/level-140](https://backrooms-wiki.wikidot.com/level-140) |
| 092 | Level 149 | The Coconut Isles | [https://backrooms-wiki.wikidot.com/level-149](https://backrooms-wiki.wikidot.com/level-149) |
| 093 | Level 160 | The City of Promised Memories | [https://backrooms-wiki.wikidot.com/level-160](https://backrooms-wiki.wikidot.com/level-160) |
| 094 | Level 197 | Crystal Caverns | [https://backrooms-wiki.wikidot.com/level-197](https://backrooms-wiki.wikidot.com/level-197) |
| 095 | Level 201 | A E S T H E T I C | [https://backrooms-wiki.wikidot.com/level-201](https://backrooms-wiki.wikidot.com/level-201) |
| 096 | Level 263 | Pretty Pink | [https://backrooms-wiki.wikidot.com/level-263](https://backrooms-wiki.wikidot.com/level-263) |
| 097 | Level 320 | The New and Improved Entertainland! | [https://backrooms-wiki.wikidot.com/level-320](https://backrooms-wiki.wikidot.com/level-320) |
| 098 | Level 737 | Dune Eternal | [https://backrooms-wiki.wikidot.com/level-737](https://backrooms-wiki.wikidot.com/level-737) |
| 099 | Level 899 | Yonder's End | [https://backrooms-wiki.wikidot.com/level-899](https://backrooms-wiki.wikidot.com/level-899) |
| 100 | Level 998 | A Path Across Hell, and Towards Any Beyond | [https://backrooms-wiki.wikidot.com/level-998](https://backrooms-wiki.wikidot.com/level-998) |


## 3. Evidence-based popularity priorities without a fake consensus

Use an actual popularity/importance evaluation, not subjective meme recollection alone. Build `docs/production/POPULARITY_AND_SELECTION.md` with:

- Site-derived signals: top-rated level ranking, yearly top-page lists, number of recent source revisions, and whether an ID is strongly associated with a recognizable Backrooms experience. **A wiki upvote score is a partial proxy, not a worldwide cross-platform popularity metric**. Capture dated counts, methodology and links; no invented numbers.
- Gameplay suitability: strong visual identity, spatial grammar, mechanic uniqueness, navigable transitions, content feasibility and visual/audio distinctiveness.
- Technical cost: reusable systems without becoming palette swaps, real geometry/physics/render budget, entity/AI and interaction costs, licensing.
- Canon completeness: readable published page vs draft/rewritten/empty slot, source contradictions, available authorized assets.

Priority flagship set (after actual page verification): 0–14, 19, 37, 188, 48, 69, 94, 200, 256, 289, 404, 601, 808, 906, 974, 994, 999, 0.1, 6.1, 5.1, 75, 79 and additional highly rated pages. This is an **initial triage set**; avoid spending months polishing one famous level while the remaining 80 are placeholders. Reserve explicit delivery capacity for all 100.

The roster is locked for accountability, but if a URL no longer holds a usable numbered article, **do not fake that level**. Record `BLOCKED_SOURCE`, propose a single quality-equivalent replacement with its concrete Wikidot page and popularity rationale, and only update the manifest via a documented decision. Never quietly shrink the target or replace missing pages with generic content. An unavailable source is a genuine blocker, not a license to invent canon.

The Hub and unnumbered spaces (such as The Blue Channel, The Red Rooms and other documented unnumbered destinations) are **supporting nodes** in the world map where the relevant sourced continuity permits them. If fully implemented they are *bonus* destinations, not substitutions for the numbered 100. Their entries/exits and keys need source citations.

## 4. Define “100 high-quality playable levels” operationally

A level is **FULLY PLAYABLE** only if it has all applicable elements below:

**A. Canon:** correct scene identity, no contradictory entities/events, documented and classified entry/exit rules, authored additions labeled, page attribution and revision locked. 100/100 must pass these **binary** checks.

**B. Distinct lived-in/abandoned world:** an authored iconic anchor (or a canon-valid minimal-space phenomenon), correct scale and material language, multiple meaningful sightlines/regions where allowed, unique audio, nonrepetitive detail, contextually meaningful props. The player must not be able to confuse the environment with a palette swap of another level.

**C. Three-dimensional traversability:** every modeled walkable/buoyant/climbable area must be physically reachable or intentionally inaccessible with explanation; genuine floor openings and stair/ramp/platform topology where applicable. No floating staircases ending in ceilings, invisible barriers at doors, fake window tunnels, dead ends caused by colliders, or unreachable spawned objectives. Open lands and compact rooms are exempt from artificial vertical stacking but not from spatial coherence.

**D. Interaction/phenomena:** each world implements its *canonical defining mechanic* as a stateful system when the page describes one (e.g. altered darkness, underwater physics, space-folding, psychological distortions, unusual exit condition, equipment limitations). Collectibles, puzzles or puzzles-with-solutions should exist **only where compatible**; never require all worlds to share the same quest loop.

**E. Exploration density:** evaluate **perceived novelty per minute and discoverability**, not a raw prop counter. Within a reasonable sampled exploration (e.g., 10–20 minutes for expansive levels, shorter if canonically finite) the player should observe meaningful environmental or behavioral novelty without a long run of repeated box cells. Story clues are curated, not spammed. For extensive/infinite levels, show demonstrably different samples across at least **three distinct seeds**, with coherent regional transitions and recognizable landmarks.

**F. Navigation/progression:** canonical entrances/exits actually execute in-game, correct trigger conditions, no forced manual commands; an optional non-intrusive developer hint mode can show route clues tagged `SOURCE`, `ADAPTATION`, or `DEBUG ONLY`. Horror can be disorienting while controls remain usable. No perma-softlocks unless intentional and accurately documented; provide a developer recovery route that does not overwrite story progress.

**G. Engine & quality:** scene loads in Godot with no blocking errors, collision/navmesh and spawn valid, gamepad/mouse/keyboard menus work where supported, exit transitions preserve correctly scoped player state, audio/visual accessibility basics, sampled memory and frame time within budget, no reproducible major crashes.

**H. Evidence:** save actual in-engine screenshot(s), test log and short evidence walkthrough or reproducible camera path; review and sign off a 1-page per-level QA report. A rendered mock-up, static asset view or AI-generated image never qualifies as runtime evidence.

Do **not** count a destination if its level selection button leads to a uniform boilerplate scene with only a title and a portal. The release build must expose clearly marked `LOCKED / IN DEVELOPMENT` on unfinished entries; the target remains 100, but status claims must stay truthful.

### One-hundred-level quality gates

- **100/100** source pages resolved or source-blocked with an approved replacement; source-title/ID mapping tested.
- **100/100** gameplay scenes load from the same release build, not merely scripts.
- **100/100** real-world exits or appropriately documented exceptional exits are tested; developer jump is a separate channel.
- **100/100** unique identity inspections and gameplay/geometry smoke tests.
- **100/100** correct attribution and asset provenance record.
- **100/100** in-engine start/pause/resume/restart/save/return tests at representative checkpoints; every level individually reachable in developer mode.
- Test actual physical traversal/AI/physics and canon hazards in the levels that use them. **Do not assert 100 worlds meet the gate unless they actually do.**

## 5. Architecture: replace the V62 procedural boxes, not their count

Inspect the current V62 code before rewriting anything. Keep useful modules and assets only if they help the rebuilt system. Create architecture documents and a vertical prototype demonstrating the design, then expand:

```text
res://
  autoload/
    SessionState.gd       # story vs developer sandbox and save scopes
    LevelRegistry.gd      # canonical IDs + source + runtime status
    TransitionService.gd  # rule-checked no-clipping and world loading
    SaveService.gd        # versioned atomic save + migrations
    Telemetry.gd          # optional local performance/QA logs
  core/
    player/              # movement, swimming, climb, crouch, collision
    interaction/         # interactables, examined notes, inventory as needed
    world/               # level state, seeded generation, origins, streaming
    routing/             # typed directed exit edges, conditions, rule traces
    graphics/            # world environment, post effects, quality tiers
    audio/               # level-specific soundscape, occlusion
    qa/                  # seeded scenarios, bots, camera routes, screenshots
  levels/
    L000/               # iconic authored anchors, procedural grammars, scripts
    L007/
    L037/
    L188/
    ...                  # stable ID encoding for sublevels and large numbers
  data/canon/
    levels.json
    transitions.json
  docs/canon/
  docs/production/
  tests/
```

**World graph:** a typed directed multigraph. `LevelID -> LevelID` edges carry `source_url`, `source_section`, `trigger_type`, `conditions`, `risk`, `confidence`, `story_allowed`, `debug_only`, and `test_fixture`. Conditional no-clip edges must not secretly become generic Area3D level swaps. Dynamic or random exits must use reproducible seeded probabilities and deterministic testing overrides.

**Generation:** use level-specific grammars. An anchored macro-graph defines regions, circulation and special rooms; an intermediate 3D navigation/visibility graph solves connectivity and edge risks; microgen inserts constrained architectural modules, furniture/props, wear/decay and sound zones. Allow unusually large authored spaces; stream chunks only when appropriate to that world. The generator MUST check floor clearance, water volumes, exit reachability, vertical connectors, door widths, room overlaps, navmesh links and safe spawn clearances before use.

**No fake infinity:** if a level is infinite in lore, create a convincing finite streaming *experience* with stable world coordinates, region IDs, seed determinism and fog/horizon design; explicitly distinguish playable-world technical bounds from canonical spatial infinity in docs. Do not claim to literally simulate an infinite universe.

**Levels are not all alike:** dense hotel (5), flooded/vertical water (7), caves (8), midnight suburban exploration (9), agricultural expanse (10), anomalous city (11), minimal abstract (12), apartments (13), nocturnal forest (14), pool volumes (37), courtyard/windows (188), compact pink house (974), etc. One giant tile generator must not decide all environments.

**Authored landmarks:** give each major level one or more premium, hand-composed signature scenes; procedural variation complements rather than replaces them. Use semantic prefab families and spatial grammars instead of shallow geometry recolors. Support full interiors and exterior/interior transitions with depth, LOD and occlusion.

**Level-specific overrides:** expose mechanics via `LevelBehavior` / resources, not giant `match level_id` branches. A small room with a bizarre memory/audio phenomenon can be a fully realized level; it is not a defect because it lacks ten kilometers of corridors.

**Content data:** support robust schema versioning, caching, ID validation, content hashing, deterministic world seed records, deferred generation and editor previews. Warn at authoring time when a scene does not comply with the canonical manifest.

## 6. Make the game playable before making it larger

Fix these immediately in the actual V62 project, verifying in Godot:

- **ESC:** in-game pauses, releases mouse, opens a clickable pause menu with Resume, Level Browser (developer only), Settings, Save/Load where valid, Restart Checkpoint, Main Menu. Press Esc again resumes correctly. Menus work with mouse and keyboard; no lost cursor or dead input focus.
- **F3:** available as an explicit developer panel; searchable/filterable roster of all 100 with ID, title, status, icon/thumbnail, source lore readout and direct spawn testing. Exits not yet implemented are accurately marked incomplete. Never display a level as finished merely because a button exists.
- **F7:** no-clip flycam/inspection separate from player physics, with correct capture/release and rollback to a safe spawn.
- **F4:** configurable **DEVELOPER-ONLY** `Next Catalog Item` hotkey, optionally Shift+F4 previous. Never make F4 the canonical story exit.
- **Main menu:** Continue, New Expedition, Developer / 100-Level Browser, Settings, Credits, Quit. Developer mode must not overwrite normal saved progress. Save paths, seed scope and inventory state separated.
- **Loading:** robust asynchronous loader with fade/progress, cancels/recovers on missing resources, preserves correct state, never spawns inside collision; memory release between levels; no endless freeze.
- **Progression clarity:** provide discoverable non-spoiler environmental affordances and a togglable journal of already confirmed exits. Do not add huge in-world door signs or force all levels to be sequential. Make a player able to advance using clues when the source provides them.
- **Save safety:** versioned data + atomic writes, migration from V62, autosave at suitable checkpoints, fallback/recovery on corruption, chapter/map progress optional, reasonable special cases for memory/distortion levels.
- **Input & accessibility:** rebind keys; mouse sensitivity and invert; subtitles and volume sliders; color/brightness/contrast accommodations for necessary information; motion/bobbing/FOV options; optional hints; controller navigation if available.

A robust game UI is **not** a violation of lore: the distinction is diegetic story UI vs out-of-story developer menu. Explain this in the design doc and honor it in code.

## 7. A carefully differentiated 100-level gameplay portfolio

Build a **mechanics matrix** rather than imposing the same puzzle on 100 maps. Level behavior families could include: isolation/geometry drift; open-environment navigation; flooded exploration and oxygen/buoyancy; psychologically unreliable documentation; safely contained spaces with restricted entry/exit; environmental audio localization; danger/event conditions; social/community traces where the source actually describes them; layered vertical architecture; memory/visual recursion; item-mediated doors; safe but unsettling rest levels; and sudden transitions.

**The mechanic belongs only to levels supported by that article.** The existence of an engine module never authorizes spawning it everywhere. Keep "entity" vs "phenomenon" vs "uncertain report" vs "rumor" distinct. AI behaviors should be based on the specific referenced entity page and applicable level page, not a generic monster pack. Explicitly log `NO ENTITY PER SOURCE` where appropriate.

Examples of signature modules (source recheck required):

1. **Level 0:** excellent aged wallpaper/carpet, acoustic hum, repetitive but spatially unsettling topology, isolation, sourced no-clip toward 1. No friendly residents or zombie chase.
2. **Level 5:** believable vintage hotel with ballroom, hallways, multiple physically accessible functional spaces, and faithfully restricted elevator/exit behavior.
3. **Level 6:** darkness as an actual mechanic, with normal lighting equipment not arbitrarily defeating its canonical anomaly.
4. **Level 7:** an authentically huge indoor body of water with real swim/dive physics and navigable depth, not a flat black texture.
5. **Level 8:** multi-altitude cave topology, traversable shafts and safe/risky passages appropriate to the article.
6. **Level 9:** individually furnished/lived-in suburban interiors, streets, yards, attics and basements where compatible, midnight lighting, low repetition.
7. **Level 10:** believable crops, field topology, dirt tracks, structures and expansive, subtly shifting horizons; do not fabricate mobs.
8. **Level 11:** convincing skyline scale and walkable city districts with enterable public spaces; streaming and vistas with practical player navigation.
9. **Level 12:** deliberate minimalism, perceptual anomalies and accurate identity. Do not punish this page for not having hundreds of props.
10. **Level 13:** disturbing apartments and domestic variations (not greenhouse/survival crafting).
11. **Level 14:** nocturnal paradise-like forest with properly represented danger and perception, not bright generic forest combat.
12. **Level 37:** carefully authored poolrooms, acoustics, true variable water depth, ambiguity and tranquility; **no routine entity combat**.
13. **Level 188:** powerful actual courtyard vertigo and window-specific rules. Multiple real walkable heights and dangerous visual access to windows.
14. **Level 94:** Wikidot **Motion**; verify its actual visual/mechanic requirements before making anything. Do not paste in an unrelated Fandom TV/cartoon map.
15. **Level 974:** small pink domestic experience, appropriate Kitty behavior and the particular documented gift-mediated exit; a large or dense floor plan would be **less** faithful.
16. **Level 601:** adapt the chosen numbered page's The End logic. Do not force an easy victory screen unless literally supported.
17. **Level 404:** the source's unusual typography/format/psychology may require unconventional interaction and UI. Do not turn it into an ordinary gray office.
18. **Level 906:** first verify the current Cygnus Archive article's physical/inhabitant/source details; build distinctive spaces and systems, not an arbitrary book-lined lobby.
19. **Level 0.1:** accurate large-scale Zenith Station and its nested relation with Level 0; distinct 3D structural reasoning.
20. **Level 100:** Wikidot current **Brief Peace**; do not borrow a different franchise's meaning of this number.

For the remaining 80, Opus must produce equivalent per-level authored dossiers and implementation plans backed by source pages, and then implement them. These 20 examples are **not** a license to make the other 80 lower-grade.

## 8. Large-scale non-linear exploration and the 100-level world graph

- Construct `docs/production/WORLD_GRAPH.md` and a reproducible graphical export (DOT, SVG or PNG) with **exactly the 100 roster node IDs**, plus separately styled auxiliary Hub/unnumbered nodes.
- Distinguish `CONFIRMED`, `RUMORED`, `CONDITIONAL`, `ONE-WAY`, `DANGEROUS`, `ADAPTATION (labeled)` and `DEBUG_ONLY` edges; all edges have a source.
- Validate all story edges that are implemented; check true direction and conditions, post-transition spawn, persistence, whether inputs/materials are needed and whether outcomes are random.
- Reachability from Level 0 must be measured under real rules. **Do not fabricate a canon exit to guarantee all 100 are connected to Level 0.** If a selected level is inaccessible via a supported route in current content, list it honestly as developer-accessible only until a legitimate source-based route exists. The level can still be a fully playable standalone destination, but its story-reachability status must be transparent.
- Support a metagame for exploration: journal entries only for witnessed exits, optional map of *known* transitions, portable hints where lore-compatible, distinct seed travel paths, in-world histories that do not compromise isolation rules.
- If 100-level source routes create disconnected components, source and visualize them; propose documented bridge options for user approval rather than spoofing the lore.

## 9. Visual fidelity & atmosphere: industrial-quality *production*, not industrial *worlds*

Godot 4.x, Forward+ desktop target. Create high-quality PBR materials, deliberate roughness/normal breakup, photometrically coherent illumination, localized acoustic reverberation, realistic and distinct scale, sensible geometry, high-level art direction per level. Avoid identical boxes and blurry low-res placeholders. But "beautiful" cannot replace the canonical image: loneliness, repetitive wrongness, and restrained environmental storytelling are essential.

Art direction standards:
- authored architectural silhouettes appropriate to each article; distinctive macro composition; realistic furniture, service architecture or natural forms where applicable;
- context-specific prop and material wear layers, ceiling/wall/floor seams, functional doors/windows and depth cues;
- soundscapes with occlusion/reverb, source-specific ambience and sparse audio events;
- level-specific fog/volumetrics, reflection quality and strong art controls without using haze as a crutch for empty rooms;
- water physics/surface/underwater rendering where warranted;
- distant geometry and environment streaming without collapsing sightline coherence;
- settings presets Low/Medium/High/Ultra; intelligent LOD, impostors for exteriors, occlusion and material batching.

**Performance targets are targets, not claimed results:** document the actual tested GPU/CPU/OS, resolution/preset and frame-time distribution. A reasonable reference desktop for planning is RTX 3060-class graphics, Ryzen 5 5600-class CPU and 16 GB RAM, targeting 60 FPS at 1080p on a chosen mid/high preset; exact results must be measured on hardware, with 1% lows, VRAM/CPU RAM and loading times. For developers without a GPU, at least run headless functional tests and mark visual/performance evidence **UNVERIFIED**. No mock screenshot can pass a real-render test.

## 10. Modular production without copy-paste content

Make **families of reusable systems, NOT recycled worlds**. Reuse the player movement controller, save/transition graph, shader infrastructure, inventory state, procedural spatial tools, NPC scheduler and QA harness. Do not reuse an entire world layout and change its paint. Set a duplication detector: for each pair of levels compare the generated room-graph motifs, mesh/resource histogram, signature landmark set and rendered sampled images; flag excessive overlap for human review.

Include procedural variants with reproducibility and real coverage:
- At least three fixed seeds for each procedural level at the acceptance stage.
- Record region/landmark distributions and route traversability.
- 3D nav path checks across all required connectors for architecture-heavy levels.
- Long-session streaming test for any level with endless/large-scale generation, chunk unload/reload consistency and stable save coordinates.
- Asset budgets and packed-scene references, prevent broken links after moving files.

Never add twenty props to an empty room and claim novelty. Make new **places with topology, visibility, atmosphere and meaningful conditions**, and keep compact original rooms compact where canonical.

## 11. Real QA automation and human-style playthroughs

Automate `--headless --editor --quit` scene import/parsing and runtime smoke tests, but also run the actual engine in graphical mode where available. Provide reproducible `scripts/qa/run_all.sh`, `scripts/qa/run_all.ps1`, `scripts/qa/playthrough_level.sh` or equivalents. The tests must cover:

1. **100 registry entries** and 100 distinct valid scene paths, no duplicate IDs or generic copy maps under different names.
2. Full source title/URL mapping and lore lint; separate graph file with no unauthorized canonical transition edges.
3. All 100 scene loads and checkpoint player spawn clearance, playable controls, non-null collision; UI test Esc, mouse capture/focus, pause/resume, F3 panel, search/selector, F7 flycam, debug/story save isolation.
4. Doors, stairs, ramps, lifts, swim surfaces, crawlspaces, no-clipping thresholds, moving geometry and destination spawn correctness where present.
5. All 100 canonical entrances/exits actually used by playthrough fixtures, unless source genuinely supplies no confirmed playable exit; do not make an invented teleport to satisfy a test.
6. Deterministic seed checks, navigation reachability tests, transition condition branch tests, entity spawns and danger rules per canonical page.
7. Memory/leak/LOD/frame-time sample and screenshot/video evidence on representative GPUs; visual checks per actual level, not renderer placeholders.
8. Regression on known V62 failures: Esc dead UI, mouse locked in pause, Level Browser inaccessible, teleport fails, only one floor, fake empty house, portal in blocked corridor, task unreachable, random generation of unreachable ramps, corrupted/overwritten saves.
9. Save/load migration from previous releases and corrupted/unknown-data fallback.
10. License inventory and external asset integrity; no unlicensed sample assets in the final ZIP.

At every milestone write machine-checkable `reports/LEVEL_ACCEPTANCE.csv` fields: `level_id`, `canonical_source_resolved`, `correct_identity`, `unique_signature`, `complete_scene`, `real_entrance_tested`, `real_exit_tested`, `nav_and_collision_tested`, `has_gameplay`, `save_tested`, `actual_engine_tested`, `screenshots`, `fps_evidence`, `lore_reviewer`, `qa_status`, `blocker`. Boolean fields are **not** set true merely because a script would likely work.

Evidence format:
- one captured still per distinct major area / representative sublevel;
- a reproducible player traversal or test bot route for at least one legal exit;
- a recorded completion report for each playable level;
- aggregate progress histogram, performance regressions and known blockers.

Explicitly display counters: `100 requested / N source-audited / N playable-in-engine / N lore-validated / N fully accepted / N story-reachable`. These are separate metrics. Never report "100 complete" when only registry entries or debug destinations exist.

## 12. Milestones, work allocation and the anti-shallow-expansion protocol

**M0 — repository intake (do first).** Inspect V62 with tree, source, dependency and asset audit. Commit baseline. Try launching/importing Godot and record actual version/capabilities. Identify failure reproduction steps. Generate the initial 100-level source audit and prioritized backlog. Do not commit a 100-row JSON file and declare victory.

**M1 — controls and true gameplay base.** Fix Esc/F3, player controller, safe spawn, loading/transition separation, save migration, audio/settings, QA bot and screenshot capture. Create an actual working vertical demonstration with Levels 0, 5, 7, 8, 11, 37, 188 and one radically different level (e.g. 974 or 404). Verify each is recognizable, spatially convincing, playable, and canon-compliant.

**M2 — first 20 premium complete.** Not "20 placeholders": 20 levels pass all applicable acceptance gates, each with a unique signature, sourced transitions, test evidence and photographed in-engine scenes. Add first major high-value fan favorites and distinctive structures. Fix regressions before adding more.

**M3 — 40 accepted / 100 sourced.** Expand generation families, interactivity and content tooling; 100% of entire roster's source identities audited, even if only 40 are playable. Check reuse-versus-identity carefully; independent review of 10 randomly sampled completed levels.

**M4 — 70 accepted / all major families.** All geometry families represented, graph transitions working wherever source-authorized, long-session streaming and inventory persistence, QA backlog with prioritized bugs. Perform a real external-style playtest checklist.

**M5 — 100 accepted.** Exactly 100 genuinely playable, canon-audited entries. Source and license checks, real engine test, build, versioned release, completion matrix, documented unimplemented canonical exits (if any), packaged GitHub repository and ZIP. Separate "standalone playable" from "connected in story" claims.

**The quality ratchet:** no milestone may lower acceptance standards, auto-approve hundreds of scenes with a generic script, or redefine "level" down to a prefab thumbnail. If capacity runs out mid-milestone, deliver the highest quality partial implementation and transparent scoreboard. **Do not claim a finished 100-level game unless the real release truly passes.** Prioritize functional code over essays and fake metrics. Submit honest incremental progress.

## 13. Work efficiency for Opus / multi-agent execution

You are free to use multiple collaborators or parallel worktrees if available. Do not let them all edit the same central player/loader files. Split tasks: canonical research & matrix; core controls; streaming/geometry; art/audio; level bundles; QA/metrics; integration and code review. Version the interface contracts first. Each worker must be told the selected canon and cannot invent article facts. Human-style editorial review before merging a level as accepted.

Use CI for headless import and lore lint. Enforce narrow reproducible commits; hash asset sources; avoid giant opaque outputs in Git. Track large imported assets with appropriate LFS when available and permitted. Keep tests alongside implementations. Preserve exact published licensing and asset attribution. Keep work-in-progress scenes behind explicit feature flags/`IN_DEVELOPMENT` state instead of presenting them as shipped.

## 14. Required deliverables and repository layout

Create and maintain:

- `README.md` with real OS/Godot version, setup and how to actually run;
- `docs/canon/CANON_POLICY.md`, `LEVEL_100_MATRIX.csv`, per-level source dossiers, conflict register, graph provenance and license inventory;
- `docs/production/GAME_VISION.md`, `WORLD_GENERATOR_ARCHITECTURE.md`, `LEVEL_CONTENT_BUDGET.md`, `POPULARITY_AND_SELECTION.md`, `MILESTONES.md`;
- `data/canon/levels.json`, `data/canon/transitions.json`, manifests and versioned save state;
- `res://levels` with **real content** (audited scenes, assets, level-specific behavior) and no unresolved references;
- source-linked material/license inventory, correct attribution/credits UI;
- `scripts/qa/` and `tests/` with reproducible import, full scene load, routing, physics, performance and screenshot scripts;
- `reports/LEVEL_ACCEPTANCE.csv` and `reports/QUALITY_SCOREBOARD.md`;
- screenshots/videos captured *from real Godot runs*, clearly marked with engine version/seed/level/quality preset;
- packaged full source ZIP plus runnable desktop export where exporter environment permits it.

Git workflow: preserve the existing project history if possible; use an isolated feature branch and integrate tested changes. Do not delete the prior V62 state or destroy authoring evidence. Commit/push to GitHub **only if repository authorization and credentials are present**; otherwise provide local commits and a bundle or clear instructions. Never claim a successful push unless remote HEAD confirms it.

## 15. Implementation procedure: do not stop at a design pitch

1. Open this mandate and the V62 project. Confirm the project actually imports into Godot. Identify the 18 existing level identities and the source of procedural repetition.
2. Build `LEVEL_100_MATRIX.csv` with *actual source facts*. Resolve candidates and page conflicts. Print the sorted 100 IDs and report unresolved article pages. Read licensing guide.
3. Reproduce and repair P0 usability bugs first. Test in-engine.
4. Design the world graph, source-locked transition mechanism, per-level reusable systems and deterministic 3D grammar.
5. Implement and validate an eight-level deep vertical slice before mass expansion.
6. Produce the premium content campaign in batches, gate each batch with QA and canon review. Do not skip to the next batch if existing finished content no longer passes.
7. Commit changes and source docs; continuously update scoreboard and issue log.
8. When interrupted, leave a `docs/production/NEXT_SESSION_HANDOFF.md` containing exact commit, actual running tasks, blockers, latest test commands, finished/remaining counts and highest-value next steps. This is a handoff file, not a pretense of background execution.

## 16. What success and failure look like

**SUCCESS:** A real Godot build with 100 diverse, accessible (at least in developer mode), canon-correct, carefully crafted level experiences; genuine multilevel traversal where appropriate, strong distinctive environments, meaningful lore-appropriate exploration, dependable UI, correctly sourced unusual routing, stable saves, realistic performance, transparent licenses, complete per-level engine QA and source-attributed evidence.

**FAILURE:** 100 labels on the pause menu; one generic box scene with 100 materials; 100 one-room sample homes; copied maps with slightly different fog; all levels hardwired to a sequential next-level button in story mode; borrowed Fandom descriptions mislabeled Wikidot; entity spam; static test passes used as proof of gameplay; fictional screenshots; no Godot execution; unlicensed image/music packs; or claimed completion in the absence of 100 accepted level reports.

**FINAL OPERATING ORDER:** Begin implementation now. You must preserve canon accuracy **and** the 100-level goal by scaling reusable technical systems, automated acceptance, curated architectural families and content production—not by weakening world identity. Report real progress honestly with a machine-auditable scoreboard and working build. Do not terminate after providing a plan.
