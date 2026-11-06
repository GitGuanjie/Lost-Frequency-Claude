# Canon dossier brief (LOST FREQUENCY — 100-level Backrooms adaptation)

You are producing source-locked canon dossiers for a Godot 4.5 game that adapts the
**English Backrooms Wikidot** (https://backrooms-wiki.wikidot.com/). The selected
continuity is ONLY that wiki's current page for each ID. Do not use Fandom, Kane Pixels,
YouTube or your memory of other Backrooms canons. Do NOT browse the web: the source
snapshot for each level is a local text file captured on 2026-11-04 (dated, with revision).

## Inputs
For each stable id `SID` in your batch, read
`sources/wiki_text/<SID>.md`.
Header lines give URL, revision, last-edited date, access date, the page's own
"Cite this page as" authors, the page creator, and rating. The body is the linearised
article; `[bracketed]` lines are image captions; a link-target list and image credits follow.
Read the whole article body (long pages: read in chunks with offset/limit). Entrances/exits
are often under headings such as "Entrances and Exits", "Entrances:", "Exits:".

## Outputs (write both for every SID)
1. Dossier markdown: `docs/canon/levels/<SID>.md`
2. Structured JSON: `sources/dossier_json/<SID>.json`
Write nothing else in the repository.

### Hard rules
- Every fact must come from the article text. If the page is silent, write "not stated".
  Never fill gaps from general Backrooms knowledge. Never invent entities, exits or items.
- Quotes: verbatim, short (max 25 words each), attributed to the section they come from.
  At most ~8 quotes per level. No long passages (CC BY-SA 3.0 attribution + brevity).
- Distinguish **article statements** from **in-universe testimonies / logs / interviews**
  (these may be unreliable narrators). Label testimony-derived facts as `TESTIMONY`.
- Entities: classify each as `CONFIRMED` (article states it inhabits/appears),
  `REPORTED` (sightings/testimony), `RUMORED`, or write `NO ENTITY PER SOURCE` when the
  page says the level is devoid of entities or names none. Absence is important canon.
- Exits/entrances become directed edges. For each give: destination/origin as written,
  the wiki slug from the link list when present (e.g. `/level-1`, `/level-0-2`), the
  numeric id (`"1"`, `"0.2"`, `"37.1"`) or null for non-level places (e.g. "the Frontrooms",
  "Level Fun"), method, trigger type, conditions, risk, confidence, and a short quote.
  trigger_type ∈ {noclip, walk_in, door, stairs, elevator, fall, swim, dive, interact,
  item, condition, timed, sleep, death, vehicle, unknown}.
  confidence ∈ {CONFIRMED, RUMORED, CONDITIONAL, ONE-WAY, DANGEROUS, UNKNOWN}
  (combine with "+" if needed, e.g. "CONFIRMED+ONE-WAY").
- Flag unusual formats (narrative-only, typographic/psychological pages, interactive
  tabs, poems) in `source_completeness` and explain what that means for a game adaptation.
- Flag content warnings (gore, self-harm, suicide, abuse, body horror) briefly.

## What the game engine can do (keep implementation plans realistic)
Godot 4.5, Forward+. Geometry is authored in GDScript (batched boxes, ramps, stairs,
cylinders, slabs, arches, water volumes) with procedural shader materials (wallpaper,
carpet, ceiling tile, concrete, ceramic tile, water, metal, wood, plaster, brick, asphalt,
grass, sand, rock, glass, emissive panels, unlit void). Seeded deterministic chunk
streaming for very large/"infinite" levels. Dynamic light pool, per-level fog/environment,
level-specific synthesized audio (ballast hum, room tone, water, wind, crickets, transformer
drone, rain, thunder, chiptune, pads, music box, footsteps per surface), reverb per level.
Player: walk/sprint/crouch/jump, swim with buoyancy and oxygen, ladders, flashlight with
per-level policy, interact/examine notes, simple inventory flags. ExitTrigger types listed
above, with conditions and seeded probabilities. Simple scripted entity agents are possible
but ONLY when the source supports them. A canon-valid compact or near-empty level is fine:
build its phenomenon, not artificial room count. Do not force combat, quests, collectibles,
entities or tall towers where the page does not support them.

## Dossier markdown template (keep to ~60–150 lines)
```
# <SID> — <exact page title as captured>

| Field | Value |
|---|---|
| Source | <URL> |
| Revision / last edited | rev <N>, <date> UTC (accessed 2026-11-04) |
| Cite as | "<page title>" by <cite authors>, from the Backrooms Wiki. CC BY-SA 3.0 |
| Page creator (history) | <creator>, <date> |
| Survival class (as stated) | <verbatim class line or "not stated"> |
| Source completeness | COMPLETE / PARTIAL / NARRATIVE_FORMAT / UNUSUAL_FORMAT — <one line> |
| Content warnings | <none / list> |

## Source facts
| # | Fact (paraphrase) | Basis | Section | Short quote |
|---|---|---|---|---|
(10–25 rows: physical identity, scale/topology, materials, lighting, sound, anomalies,
hazards, items, communities/bases, verticality, time/weather, special rules)

## Entities
(table: name | CONFIRMED/REPORTED/RUMORED | behaviour per source | quote) or
`NO ENTITY PER SOURCE` with the supporting quote.

## Entrances (directed edges into this level)
| From | id/slug | Method | Trigger | Conditions | Confidence | Quote |

## Exits (directed edges out of this level)
| To | id/slug | Method | Trigger | Conditions | Risk | Confidence | Quote |

## Signature mechanic and in-game implementation plan
SOURCE FACT → SPECIFIC IN-GAME IMPLEMENTATION (bullets). Include: layout grammar
(authored anchors + procedural fill), materials/lighting/audio identity, the defining
stateful mechanic, how each implementable exit is triggered, what verticality is
appropriate (or explicitly none), entity policy, and what must stay ABSENT.

## Canon traps (do not)
Bullets of tempting but wrong design choices for this page.

## Test evidence
Pending implementation. (Filled by QA when the level is built.)
```

## JSON schema (one object per SID)
```json
{
 "stable_id": "L000", "level_id": "0", "title": "Threshold",
 "survival_class": "verbatim or not stated",
 "physical_identity": "<=300 chars",
 "scale_topology": "<=200 chars (finite/infinite, indoor/outdoor, vertical structure)",
 "anomalies": ["short items"],
 "lighting_sound": "<=200 chars",
 "entities": [{"name": "", "status": "CONFIRMED|REPORTED|RUMORED", "behavior": "<=120 chars"}],
 "entity_policy": "NO ENTITY PER SOURCE | SOURCED ENTITIES ONLY: <names>",
 "hazards": ["short items"],
 "items_communities": ["short items"],
 "entrances": [{"from": "", "from_id": "0 or null", "slug": "/level-x or null", "method": "", "trigger_type": "", "conditions": "", "confidence": "", "quote": ""}],
 "exits": [{"to": "", "to_id": "1 or null", "slug": "/level-1 or null", "method": "", "trigger_type": "", "conditions": "", "risk": "", "confidence": "", "quote": ""}],
 "signature_mechanic": "<=300 chars",
 "verticality": "<=160 chars",
 "do_not": ["short items"],
 "content_warnings": ["short items"],
 "source_completeness": "COMPLETE|PARTIAL|NARRATIVE_FORMAT|UNUSUAL_FORMAT",
 "conflicts_notes": "<=300 chars (contradictions inside the page, roster title mismatch, etc.)",
 "key_quotes": [{"section": "", "quote": "<=25 words"}]
}
```
Validate each JSON file parses (e.g. `python3 -c "import json;json.load(open(p))"`).

## Final reply
A compact table: SID | source_completeness | #entities | #entrances | #exits | notes/blockers.
No other commentary.
