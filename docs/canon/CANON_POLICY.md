# Canon policy

## Selected continuity
**English Backrooms Wikidot** (https://backrooms-wiki.wikidot.com/). This is a project-selected
continuity, not "the" official Backrooms. Fandom, Kane Pixels, YouTube series, other Wikidot
branches and older snapshots are **not** sources. Alternative-continuity modules (e.g. "Level !",
"Level Fun", "Level 3999") are out of scope unless the user explicitly authorises a separate,
clearly marked module, which would never count toward the 100.

## Source of truth and dating
- Each roster entry is locked to the live page at its URL, captured **2026-11-04**. We record the
  page title, Wikidot revision, last-edited time, access time, the page's own "Cite this page as"
  authors and the page creator from revision history (`data/canon/levels.json`).
- Offset-paginated pages are captured in full (all `/offset/N` sections).
- When a page is revised later, re-capture it, diff it, and update the dossier, manifest and
  CONFLICTS register before changing the level.

## Citation rules
- Dossiers (`docs/canon/levels/<SID>.md`) map **SOURCE FACT → IMPLEMENTATION → TEST EVIDENCE**.
  Short verbatim quotes (≤ 25 words) carry their section. Testimony and logs are labelled as such.
- Every story exit in a level manifest is either `SOURCE` (it references a documented edge id
  and quote in `data/canon/transitions.json`) or `ADAPTATION` (with a stated reason). The QA lint
  enforces this. Developer jumps (F3/F4) are never edges.
- In-world texts are paraphrases written for the game, not copied passages.

## Interpretation rules
1. **Absence is canon.** "Devoid of entities" means none are spawned. Rumoured entities are at most
   ambiguous phenomena, labelled REPORTED/RUMORED, and never combat encounters.
2. **Conflicts inside a page:** prefer the article voice over testimony, the current section over
   archived tabs, and the more conservative reading. Record the choice in the manifest `notes`
   and in CONFLICTS_AND_REWRITES.md.
3. **Scale:** "infinite" levels are finite streaming windows with stable coordinates. Docs and
   UI say so; we never claim to simulate infinity.
4. **No fabricated routes:** an unreachable level stays developer-accessible only, and is marked
   that way in the scoreboard. Exits to unbuilt or unnumbered places are recorded honestly and
   offer a labelled, non-canon release-boundary return.
5. **Compactness:** a canonically small or empty place stays small or empty. Fidelity beats room
   count.

## Blocking rule
A level with an unresolved critical source conflict, or a source that can't be read, is
`BLOCKED_SOURCE` and can't be promoted. Replacing a roster entry requires a documented decision
naming a concrete Wikidot page and the popularity rationale. Current state: 100/100 sources
resolved, 0 blocked (L320 and L289 needed full offset capture; see CONFLICTS_AND_REWRITES.md).
