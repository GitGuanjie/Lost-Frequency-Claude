"""Regenerate data-driven canon/production docs from committed data:

    python3 -I tools/build_docs.py [--dossier-json DIR]

Writes docs/canon/ATTRIBUTION_AND_LICENSES.md, docs/canon/CONFLICTS_AND_REWRITES.md,
docs/production/POPULARITY_AND_SELECTION.md and assets/ASSET_PROVENANCE.csv.
"""
import argparse
import csv
import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def norm(t):
    return re.sub(r"[^a-z0-9]+", "", unicodedata.normalize("NFKC", t or "").lower())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dossier-json", default=None)
    a = ap.parse_args()
    roster = json.loads((ROOT / "data/canon/levels.json").read_text(encoding="utf-8"))["levels"]
    feeds = json.loads((ROOT / "docs/production/evidence/top_rated_feeds_2026-11-04.json").read_text(encoding="utf-8"))
    dj = Path(a.dossier_json) if a.dossier_json else None

    # ------------------------------------------------ attribution & licences
    L = ["# Attribution and licences", "",
         "## The adaptation's licence",
         "The Backrooms Wiki's Licensing Guide (https://backrooms-wiki.wikidot.com/licensing-guide, rev 16, read 2026-11-04) "
         "says that Backrooms games must be released under **CC BY-SA 3.0** (or GPLv3 with full playable source). A prominent "
         "release statement is required wherever the game is distributed. Paid releases may not use DRM, may not add legal "
         "restrictions through EULAs, and may not impede alternative distribution. LOST FREQUENCY therefore releases the whole "
         "`lost_frequency/` folder (code, data, docs, generated media) under **CC BY-SA 3.0**; see `LICENSE.md`. This is not "
         "legal advice. Get a real review before any commercial distribution.", "",
         "> Release statement: Content relating to the Backrooms is licensed under Creative Commons Sharealike 3.0 and all "
         "concepts originate from http://backrooms-wiki.wikidot.com/ and its authors. LOST FREQUENCY, being derived from this "
         "content, is hereby also released under Creative Commons Sharealike 3.0.", "",
         "## Media", "No images, models, fonts or audio from the wiki or elsewhere are shipped. Every texture is a procedural shader "
         "and every sound is synthesised at runtime (see `assets/ASSET_PROVENANCE.csv`). Page images are separately licensed per "
         "page licence box and are **not** used. In-world texts are paraphrases. Short source quotes appear only in the dossiers "
         "and manifests, with attribution.", "",
         "## Source pages (100, accessed 2026-11-04)", "",
         "| Slot | Page | Cite as (page licence box) | Page creator (history) | Rev | Last edited (UTC) | URL |",
         "|---:|---|---|---|---:|---|---|"]
    for e in roster:
        L.append(f"| {e['slot']} | {e['page_title']} | {e['cite_authors']} | {e['page_creator']} | {e['revision']} | {e['last_edited_utc']} | {e['url']} |")
    L += ["", "Engine: Godot 4.5.1 (MIT, © Juan Linietsky, Ariel Manzur and contributors). Physics: Jolt (MIT).", ""]
    (ROOT / "docs/canon/ATTRIBUTION_AND_LICENSES.md").write_text("\n".join(L), encoding="utf-8")

    # ---------------------------------------------------------- conflicts
    C = ["# Conflicts, rewrites and source issues", "",
         "Resolution rule: the dated live page wins. Contradictions *inside* a page are adapted conservatively, and the "
         "choice is labelled in the level manifest. A critical unresolved conflict blocks the level.", "",
         "## V62 identity errors (fixed by rebuild)", "",
         "| V62 scene | V62 identity | Selected canon | Resolution |", "|---|---|---|---|",
         "| World7Archives | drowned archive | Level 7 \"Thalassophobia\" | rebuild; archive identity removed |",
         "| World11Transit | metro transit | Level 11 \"The City That Never Sleeps\" | rebuild as a city |",
         "| World12Hangar | fractal hangar | Level 12 \"Matrix\" | rebuild; hangar removed |",
         "| World13Glasshouse | greenhouse | Level 13 \"The Boiling Frogs\" | rebuild as apartments |",
         "| World14Vents | duct maze | Level 14 \"Paradise\" | rebuild; ducts removed |", "",
         "## Capture / format issues", "",
         "- **Wikidot offset pagination**: Level 320 (13 sections, `/offset/0–12`) and Level 289 (`/offset/0–1`) keep their "
         "content in separate offset URLs. The first capture saw only the default section. Both were recaptured in full on "
         "2026-11-04 and their dossiers rewritten. For L320, offset 10 is the current article and offset 0 is the archived old "
         "Level 32 text.",
         "- **Level 922**: the live title (\"I finally travelled to the 'True End', and all I got was this fucking staircase.\") "
         "differs from the roster placeholder, as the roster expected. Recorded as RESOLVED_TITLE_DIFFERS.",
         "- **Level 73**: the title uses Fraktur Unicode. The UI shows its NFKC plain form (\"The Redlands\") because default "
         "fonts lack those glyphs.",
         "- Footnote bodies, supplementary pages and logs hosted on separate pages are not part of the captured level page. "
         "Dossiers mark the gaps.", "",
         "## Per-level notes from the dossiers", "", "| Level | Completeness | Note |", "|---|---|---|"]
    for e in roster:
        note = ""
        if dj and (dj / f"{e['stable_id']}.json").exists():
            note = json.loads((dj / f"{e['stable_id']}.json").read_text(encoding="utf-8")).get("conflicts_notes", "")
        C.append(f"| {e['stable_id']} | {e.get('source_completeness', '')} | {str(note).replace('|', '/')} |")
    (ROOT / "docs/canon/CONFLICTS_AND_REWRITES.md").write_text("\n".join(C) + "\n", encoding="utf-8")

    # --------------------------------------------------------- popularity
    overall = {norm(x["page"]): i + 1 for i, x in enumerate(feeds["top_rated_overall_feed"])}
    by_year = {norm(x["page"]): x["score"] for x in feeds["top_rated_by_year_feed"]}
    P = ["# Popularity and selection evidence", "",
         "Signals (all dated 2026-11-04, from the selected wiki only):",
         "1. **Page rating at access** from each page snapshot (net votes). This is a partial proxy and **not** a "
         "cross-platform popularity metric.",
         "2. Presence in the live **Top Rated Pages** feed (all-time top, all categories; rank shown when captured) and in the "
         "**Top Rated Pages By Year** feed (top 50 per year).",
         "3. Story-graph role: whether the level sits on a source-documented route from Level 0 (see WORLD_GRAPH.md).", "",
         "Production order is set by these signals and by gameplay suitability (visual identity, mechanic distinctiveness, "
         "feasibility). The roster itself is the user's locked target; no entry was swapped.", "",
         "| Slot | Level | Title | Rating at access | All-time feed rank | In by-year top 50 | Group |", "|---:|---|---|---:|---:|---|---|"]
    rows = []
    for e in roster:
        key = norm(e["page_title"])
        rank = overall.get(key, "")
        yr = "yes" if key in by_year else ""
        try:
            rating = int(str(e.get("rating_at_access", "0")).replace("+", ""))
        except ValueError:
            rating = 0
        rows.append((rating, e, rank, yr))
    for rating, e, rank, yr in sorted(rows, key=lambda r: -r[0]):
        P.append(f"| {e['slot']} | {e['level_id']} | {e.get('title', '')} | {rating:+d} | {rank} | {yr} | {e['group']} |")
    P += ["", "Raw feed extracts: `docs/production/evidence/top_rated_feeds_2026-11-04.json`.", ""]
    (ROOT / "docs/production/POPULARITY_AND_SELECTION.md").write_text("\n".join(P), encoding="utf-8")

    # ----------------------------------------------------- asset provenance
    (ROOT / "assets").mkdir(exist_ok=True)
    rows = [["asset", "kind", "origin", "author", "license", "notes"]]
    for sh in sorted((ROOT / "core/graphics/shaders").glob("*.gdshader")):
        rows.append([str(sh.relative_to(ROOT)), "shader", "created in-project", "LOST FREQUENCY contributors", "CC BY-SA 3.0", "procedural material/effect"])
    src = (ROOT / "autoload/AudioSynth.gd").read_text(encoding="utf-8")
    for r in sorted(set(re.findall(r'^\t\t"([a-z_]+)": s = ', src, re.M))):
        rows.append([f"autoload/AudioSynth.gd#{r}", "synthesised audio recipe", "created in-project", "LOST FREQUENCY contributors", "CC BY-SA 3.0", "generated at runtime; no samples"])
    rows.append(["icon.svg", "vector icon", "created in-project", "LOST FREQUENCY contributors", "CC BY-SA 3.0", ""])
    for j in sorted((ROOT / "reports/screenshots").glob("*.jpg")):
        rows.append([str(j.relative_to(ROOT)), "evidence still", "rendered by Godot from this project", "LOST FREQUENCY contributors", "CC BY-SA 3.0", "QA evidence; not a marketing render"])
    with open(ROOT / "assets/ASSET_PROVENANCE.csv", "w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows(rows)
    print("docs written", len(rows) - 1, "provenance rows")


if __name__ == "__main__":
    main()
