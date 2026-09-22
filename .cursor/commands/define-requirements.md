---
name: define-requirements
description: >-
  Analyze OSRP, ORIS, and Common Codes for a discipline and write
  docs/{DISC}/schedule-tile-requirements.md as a detailed delta vs
  schedule-tile-common (cases, ODF sources, BE mapping, FE behaviour,
  Schedule=S). Use when building schedule tile packs, OSRP/ORIS analysis,
  or discipline requirements.
---

# Schedule tile requirements

Argument: discipline code (e.g. `ARC`). Optional edition override after the code (default **LA28 / OG2028**).

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask for the 3-letter discipline code and stop until provided.

---

## Hard stops

1. Discipline missing from OSRP, ORIS, or Common Codes MCP → stop and report which source failed.
2. Do **not** invent OSRP/ORIS/CC facts. Cite MCP results (document versions on the first line of your reply).
3. Do **not** generate BE/FE application code — requirements markdown only.

---

## Read these templates first

Copy **structure**, not content:

| Flavour | Template |
|---------|----------|
| Shared baseline | [`docs/common/schedule-tile-common.md`](../../docs/common/schedule-tile-common.md) |
| H2H + score | [`docs/ARC/schedule-tile-requirements.md`](../../docs/ARC/schedule-tile-requirements.md) |
| Event row + medallists | [`docs/CRD/schedule-tile-requirements.md`](../../docs/CRD/schedule-tile-requirements.md) |
| Grouping context | [`docs/grouping/olympic-grouping-rules.csv`](../../docs/grouping/olympic-grouping-rules.csv) |

Also skim any existing `docs/{DISC}/schedule-tile-requirements.md` and `rawData/{DISC}/` / `ownScenarios/{DISC}/` if present (link them in Editions / RawData / Freeze).

---

## MCP tools (use in this order)

1. **OSRP** (`user-osrp-mcp`): Competition Schedule / tile UX — before / during / after, medallists, live indicators.
2. **ORIS** (`user-oris-mcp`): schedule procedures, exceptional states, IRMs (§3.1.6 or equivalent).
3. **Common Codes** (`user-Common Codes`): `CC@Unit` Schedule flags (**Y / N / S**), `CC@ScheduleStatus`, `CC@ResultStatus`, discipline `SC@*` (IRM, CompetitorPlace, Period, StartText, …).
4. **ODF verifier** (`user-odf-verifier-mcp`): XPaths, M/O, allowed values when the pack needs precise BE mapping (`check_xpath_exists`, `get_xpath_details`, `list_allowed_values`, `browse_ods_by_message`, …).
5. **Local**: always diff against `docs/common/schedule-tile-common.md`; check grouping CSV for a `{DISC}` row.

Display document versions first (OSRP / ORIS / ODF / CC) in the chat reply and in the pack header.

---

## Workflow checklist

Copy and track:

```
Progress:
- [ ] Resolve DISC + edition (default OG2028 / LA28)
- [ ] MCP: OSRP schedule tile content
- [ ] MCP: ORIS exceptional / IRM
- [ ] MCP: CC Unit Schedule Y/N/S + relevant SC@*
- [ ] MCP: ODF XPaths for tile fields (as needed)
- [ ] Read common + choose flavour (H2H vs event-row)
- [ ] Check olympic-grouping-rules.csv for DISC
- [ ] Write docs/{DISC}/schedule-tile-requirements.md
- [ ] Mandatory Schedule=S section (even if count = 0)
- [ ] Separate Backend + Frontend sections (default)
- [ ] Link DISC in docs/common/schedule-tile-common.md intro if missing
- [ ] Surface open product questions when sources conflict / under-specify
- [ ] Done: versions listed, deltas vs common explicit, open questions listed if any
```

---

## Open product questions (mandatory when inconsistent)

Do **not** invent product answers. When sources conflict, omit a needed XPath, or leave CIS/WMR behaviour ambiguous, **always**:

1. Document the gap in the pack (`## API gaps` and/or an inline note in BE/FE).
2. End the chat reply with an **Open product questions** list (numbered, concrete, decision-oriented).

Trigger examples (non-exhaustive):

| Signal | Ask about |
|--------|-----------|
| OSRP shows an indicator (e.g. Forfeit) but ODF DD has no matching field (`UI/RES_CODE`, …) | How BE should detect it until DD catches up |
| OSRP mentions medallists **and** H2H medal-game symbols | Whether medallists belong on the game tile vs event row / CIS only |
| CC `Schedule=Y` for meetings/ceremonies but UX unclear | CIS vs WMR inclusion |
| Place-code / PreviousUnit text differs from OSRP wording (“Winner Game n”) | Exact placeholder string source |
| Grouping CSV missing vs sport looks session-groupable | Confirm no `groupId` vs add CSV row |
| IRM / forfeit scores in ORIS but not on OSRP tile samples | What the tile must show |

If nothing is inconsistent, omit the list (do not invent questions).

### Flavour

From OSRP, choose one:

- **H2H + score** — match/game card with live/final score (ARC, FBL, CKT, SQU pattern).
- **Event row + medallists** — no live score on tile; after shows medallists (CRD, CLB pattern).

### Backend vs Frontend

Default: **separate** `## Backend — {DISC}` and `## Frontend — {DISC}`.  
Only merge a short FE subsection under Backend if the FE delta is trivial (1–3 bullets). Prefer separate sections.

---

## Output file

Path: `docs/{DISC}/schedule-tile-requirements.md`  
Language: **English** (same as existing packs).

### Required section skeleton

```markdown
# {DISC} Schedule Tile — Developer Requirements

**Scope:** …  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP … · ORIS … · ODF … · SC/CC …  
**RawData:** …  
**Freeze:** … (if ownScenarios/{DISC} exists)

## 1. {DISC} vs common
| Topic | {DISC} behaviour |
|-------|------------------|
| … | … |

## 2. Situations (OSRP + ORIS)
### 2.1 Before
### 2.2 During / after
### 2.3 Exceptional

## 3. Backend — {DISC}
### 3.1 ODF sources
### 3.2 Inclusion (Y + S rules)
### 3.3 … sport-specific mapping (liveCurrentProgress, placeholders, resultDecision, scores/medallists)
### 3.n Backend checklist

## 4. Frontend — {DISC}
### 4.1 Phase / tile behaviour table
### 4.2 Grouping / visibility
### 4.3 Card click redirects
### 4.n Frontend checklist

## 5. Schedule=S analysis
(mandatory — even if zero S units)
| RSC / pattern | CC Schedule | Default list | By Event | Expected grouping |
|---------------|-------------|--------------|----------|-------------------|
| … | S / — | … | … | roll-up to phase / hidden / … |

Rule: `Schedule=S` is a **visibility / grouping** concern, **not** a redirect change.
Click still opens that unit’s results RSC (unless pack documents an RSC override).

## 6. API gaps ({DISC} view)   # omit if none
## 7. {DISC} cheat sheet
BEFORE / DURING / AFTER message flow
```

Adapt subsection numbers to the sport; keep **Schedule=S analysis** and **Backend / Frontend** as first-class sections.

### Content expectations

- Explicit **deltas vs common** (do not restate the whole common doc).
- Concrete **cases** (before draw, TBD/PreviousUnit, BYE/UNSCHEDULED, IRM layouts, live progress, medals).
- **ODF → API → FE** mapping for sport-specific fields.
- Inclusion: `Schedule=Y` plus documented `S` behaviour; phases `N` usually not listed.
- Grouping: cite CSV rule or “no row → no `groupId`”; medal matches often ungrouped when applicable.

---

## After write

1. If `{DISC}` is missing from the discipline list at the top of `docs/common/schedule-tile-common.md`, add a markdown link.
2. Reply with: document versions, output path, flavour chosen, Schedule=S count summary.
3. If any OSRP ↔ ORIS ↔ CC ↔ ODF ↔ common inconsistency or underspec was found → **Open product questions** (required; do not invent answers). If none → omit.

## Definition of done

- [ ] `docs/{DISC}/schedule-tile-requirements.md` exists
- [ ] Editions / versions recorded
- [ ] vs-common table + situations + BE + FE + Schedule=S + cheat sheet
- [ ] Common intro link updated if needed
- [ ] No fabricated OSRP/ORIS/CC claims
- [ ] Inconsistencies called out as open product questions (chat + pack gaps), not silently resolved
