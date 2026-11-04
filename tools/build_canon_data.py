"""Build canon data files from the dated Wikidot snapshot + reviewed dossiers.

    python3 -I tools/build_canon_data.py --snapshot <dir with level-*.json> \
        --roster <BACKROOMS_100_LEVEL_ROSTER.csv> [--dossiers <dir with <SID>.json>]

Writes (relative to the project root):
  data/canon/levels.json            runtime roster with source metadata
  data/canon/transitions.json       source-documented directed edges (all 100)
  docs/canon/LEVEL_100_MATRIX.csv   100 source-linked rows (mandate section 1)

The raw HTML snapshot is NOT committed (size/licence); its per-page metadata is.
Implementation/QA columns are filled from levels/<SID>/level.json and
reports/qa/latest_results.json when present, never assumed.
"""
import argparse
import csv
import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sid_of(level_id: str) -> str:
    parts = level_id.split(".")
    s = "L%03d" % int(parts[0])
    return s + ("_" + parts[1] if len(parts) > 1 else "")


def norm(t: str) -> str:
    t = unicodedata.normalize("NFKC", t or "").lower()
    return re.sub(r"[^a-z0-9]+", "", t)


def subtitle(page_title: str) -> str:
    m = re.match(r'^\s*level\s+[\d.]+\s*-\s*["“](.*)["”]\s*$', page_title or "", re.I)
    return m.group(1) if m else ""


def cite_authors(lic: str):
    m = re.search(r'Cite this page as:\s*"\s*(.+?)\s*"\s*by\s+(.+?),?\s+from the Backrooms Wiki', lic or "")
    return m.group(2).strip() if m else None


def survival_line(md: str):
    m = re.search(r"SURVIVAL DIFFICULTY:?\s*(.{0,60})", md or "", re.I)
    if m:
        return re.sub(r"\s+", " ", m.group(1)).strip(" .")
    m = re.search(r"\bClass\s+(\d+|[A-Z][a-z]+|Ω|Habitable|Deadzone|Pending|Final)\b", md or "")
    return ("Class " + m.group(1)) if m else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--snapshot", required=True)
    ap.add_argument("--roster", required=True)
    ap.add_argument("--dossiers", default=None)
    a = ap.parse_args()
    snap = Path(a.snapshot)
    dos = Path(a.dossiers) if a.dossiers else None
    roster = list(csv.DictReader(open(a.roster, encoding="utf-8-sig")))
    assert len(roster) == 100, "roster must hold exactly 100 rows"
    qa = {}
    qa_path = ROOT / "reports/qa/latest_results.json"
    if qa_path.exists():
        qa = {r["stable_id"]: r for r in json.loads(qa_path.read_text()).get("levels", [])}
    levels, rows, edges = [], [], []
    seen = set()
    for row in roster:
        lid = row["level_id"].strip()
        sid = sid_of(lid)
        assert sid not in seen, "duplicate id " + sid
        seen.add(sid)
        slug = row["candidate_wikidot_url"].rsplit("/", 1)[1]
        rec = json.loads((snap / f"{slug}.json").read_text(encoding="utf-8"))
        meta = json.loads((snap / f"{slug}.meta.json").read_text())
        status_http = rec.get("http_status")
        sub = subtitle(rec.get("page_title", ""))
        roster_title = row["working_title_unverified_if_missing"]
        if status_http != 200 or not rec.get("page_title"):
            source_status = "BLOCKED_SOURCE"
        elif norm(sub) == norm(roster_title) or (sub == "" and "no subtitle" in roster_title.lower()):
            source_status = "RESOLVED"
        else:
            source_status = "RESOLVED_TITLE_DIFFERS"
        num_ok = bool(re.match(r"^\s*level\s+" + re.escape(lid) + r"\b", rec.get("page_title", ""), re.I))
        if not num_ok and source_status != "BLOCKED_SOURCE":
            source_status = "MISMATCH_ID"
        # display title: keep the page's own text but fall back to plain text when
        # the page uses decorative Unicode (e.g. Fraktur) that UI fonts lack
        display = sub
        if any(ord(ch) > 0xFFFF for ch in sub):
            display = unicodedata.normalize("NFKC", sub)
        d = {}
        if dos and (dos / f"{sid}.json").exists():
            d = json.loads((dos / f"{sid}.json").read_text(encoding="utf-8"))
        lic = (rec.get("licensebox_text") or [""])[0]
        impl = {}
        mp = ROOT / "levels" / sid / "level.json"
        if mp.exists():
            impl = json.loads(mp.read_text(encoding="utf-8"))
        entry = {
            "slot": int(row["slot"]), "group": row["priority_group"], "level_id": lid, "stable_id": sid,
            "url": row["candidate_wikidot_url"], "page_title": rec.get("page_title"), "title": display,
            "title_as_published": sub, "roster_working_title": roster_title,
            "source_status": source_status, "revision": rec.get("revision"),
            "last_edited_utc": rec.get("last_edited_utc"), "accessed_utc": meta.get("accessed_utc"),
            "cite_authors": cite_authors(lic), "page_creator": rec.get("created_by"),
            "page_created_utc": rec.get("created_utc"), "rating_at_access": rec.get("rating"),
            "license": "CC BY-SA 3.0 (text, per page licence box); media credits listed per page",
            "survival_class": d.get("survival_class") or survival_line(rec.get("markdown", "")),
            "summary": d.get("physical_identity", ""),
            "scale_topology": d.get("scale_topology", ""),
            "lighting_sound": d.get("lighting_sound", ""),
            "entity_policy": d.get("entity_policy", ""),
            "signature_mechanic": d.get("signature_mechanic", ""),
            "source_completeness": d.get("source_completeness", ""),
            "content_warnings": d.get("content_warnings", []),
            "dossier": f"docs/canon/levels/{sid}.md" if (ROOT / "docs/canon/levels" / f"{sid}.md").exists() else "",
        }
        levels.append(entry)
        for k, x in enumerate(d.get("exits", []) or []):
            to_id = x.get("to_id")
            to_sid = sid_of(str(to_id)) if to_id not in (None, "", "null") and re.match(r"^\d+(\.\d+)?$", str(to_id)) else None
            edges.append({
                "id": f"{sid}>{to_sid or 'EXT'}#{k + 1}", "from": sid, "to": to_sid, "to_label": x.get("to"),
                "to_slug": x.get("slug"), "trigger_type": x.get("trigger_type"), "method": x.get("method"),
                "conditions": x.get("conditions"), "risk": x.get("risk"), "confidence": x.get("confidence"),
                "source_url": entry["url"], "source_quote": x.get("quote"), "source_section": "Entrances/Exits",
                "in_roster": bool(to_sid and to_sid in {sid_of(r["level_id"].strip()) for r in roster}),
                "story_allowed": True, "debug_only": False,
            })
        q = qa.get(sid, {})
        rows.append({
            "slot": entry["slot"], "group": entry["group"], "level_id": lid, "stable_id": sid,
            "source_url": entry["url"], "current_page_title": entry["page_title"],
            "cite_authors": entry["cite_authors"], "page_creator": entry["page_creator"],
            "revision": entry["revision"], "last_edited_utc": entry["last_edited_utc"],
            "accessed_utc": entry["accessed_utc"], "rating_at_access": entry["rating_at_access"],
            "survival_class": entry["survival_class"],
            "physical_identity": d.get("physical_identity", ""),
            "anomalies": "; ".join(d.get("anomalies", []) or []),
            "lighting_sound": d.get("lighting_sound", ""),
            "entities": "; ".join(f"{e.get('name')} [{e.get('status')}]" for e in (d.get("entities") or [])) or d.get("entity_policy", ""),
            "hazards": "; ".join(d.get("hazards", []) or []),
            "items_communities": "; ".join(d.get("items_communities", []) or []),
            "entrances": "; ".join(f"{x.get('from')} ({x.get('trigger_type')})" for x in (d.get("entrances") or [])),
            "exits": "; ".join(f"{x.get('to')} ({x.get('trigger_type')}, {x.get('confidence')})" for x in (d.get("exits") or [])),
            "license": "CC BY-SA 3.0",
            "source_confidence": source_status,
            "content_status": d.get("source_completeness", "PENDING_DOSSIER"),
            "implementation_status": impl.get("status", "NOT_STARTED"),
            "qa_status": q.get("qa_status", impl.get("qa_status", "NOT_TESTED")),
            "conflicts": d.get("conflicts_notes", ""),
        })
    out_levels = {
        "schema": 1, "continuity": "English Backrooms Wikidot (https://backrooms-wiki.wikidot.com/)",
        "snapshot_accessed": "2026-11-04", "count": len(levels),
        "note": "Titles, revisions, authors and dates captured from the live pages on the access date. "
                "Summaries come from reviewed dossiers in docs/canon/levels.",
        "levels": levels,
    }
    (ROOT / "data/canon").mkdir(parents=True, exist_ok=True)
    (ROOT / "data/canon/levels.json").write_text(json.dumps(out_levels, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    (ROOT / "data/canon/transitions.json").write_text(json.dumps({
        "schema": 1, "note": "Directed edges documented on each source page (exits sections). "
        "Runtime story exits live in levels/<SID>/level.json and must reference one of these "
        "(or be labelled ADAPTATION). Developer jumps are not edges.", "edges": edges},
        ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    with open(ROOT / "docs/canon/LEVEL_100_MATRIX.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    by = {}
    for e in levels:
        by[e["source_status"]] = by.get(e["source_status"], 0) + 1
    print(json.dumps({"levels": len(levels), "edges": len(edges), "source_status": by}, indent=1))


if __name__ == "__main__":
    main()
