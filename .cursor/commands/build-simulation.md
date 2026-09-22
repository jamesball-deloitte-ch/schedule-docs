---
name: build-simulation
description: >-
  Build an ODF schedule-tile freeze under ownScenarios/{DISC} from
  docs/{DISC}/schedule-tile-requirements.md and rawData/{DISC}. Copy ODFs
  first, remap dates, bootstrap PARTIC/TEAMS/ENTRIES, cover before/during/after
  through medals, include Schedule=S units. Use when creating schedule tile
  simulations, freezes, or ownScenarios playback.
---

# Schedule tile simulation

Argument: discipline code (e.g. `ARC`). Optional notes after the code.

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask for the 3-letter discipline code and stop until provided.

Default pack path: `docs/{DISC}/schedule-tile-requirements.md`.  
If that file is missing → stop and tell the user to run `/define-requirements {DISC}` first.

---

## Hard stops

1. **`rawData/{DISC}/` must exist and contain ODF XML.** If not → **HARD STOP**. Do not invent a full freeze from scratch.
2. Do **not** modify files under `rawData/`.
3. Do **not** reverse medal order: always `DT_MEDALLISTS` then `DT_MEDALS`.
4. Do not generate application code — only `ownScenarios/` XML + README + `AC.feature`.

---

## Read these templates first

| Artefact | Template |
|----------|----------|
| Requirements pack | `docs/{DISC}/schedule-tile-requirements.md` |
| Freeze README (team / multi-day) | [`ownScenarios/CKT/README.md`](../../ownScenarios/CKT/README.md) |
| Freeze README (single day H2H) | [`ownScenarios/SQU/README.md`](../../ownScenarios/SQU/README.md) |
| Freeze README (Schedule=S + overrides) | [`ownScenarios/ARC/README.md`](../../ownScenarios/ARC/README.md) |
| AC.feature style | [`ownScenarios/CRD/AC.feature`](../../ownScenarios/CRD/AC.feature) |
| Grouping | [`docs/grouping/olympic-grouping-rules.csv`](../../docs/grouping/olympic-grouping-rules.csv) |

---

## MCP / tools

- **Common Codes**: confirm `CC@Unit` Schedule **Y / N / S** counts and which RSC patterns are `S`.
- **ODF verifier**: after fabricating any XML, try `validate_attached_file` (or equivalent) on fabricated messages; report pass/fail.
- Optional: OSRP/ORIS only to clarify cases already listed in the pack — prefer the pack as source of truth for this command.

---

## Pipeline (fixed order)

```
Progress:
- [ ] Gate 0: rawData/{DISC} has ODF XML
- [ ] Read requirements pack + choose cases to cover
- [ ] Create ownScenarios/{DISC}/01_Schedule_Tile_Mixed_Day/ (or _Mixed_Days)
- [ ] COPY selected ODF from rawData → scenario folder (never edit rawData)
- [ ] Remap dates / document times to LogicalDate(s)
- [ ] Bootstrap: DT_PARTIC; if teams → DT_PARTIC_TEAMS + DT_ENTRIES
- [ ] Timeline: schedule before → during → after → medallists → medals
- [ ] Include all Schedule=S units from CC that appear in feed/pack
- [ ] Pack edge cases into other events in the same simulation
- [ ] Fabricate ONLY missing messages; list them
- [ ] Validate fabricated with ODF verifier when possible
- [ ] Write README.md + AC.feature
- [ ] Final reply: Fabricated: … (even if empty)
```

### Gate 0 — rawData

```
rawData/{DISC}/ must exist and contain .xml ODF messages
If NOT → HARD STOP (do not fabricate an entire discipline dump)
```

### 1. Copy first

- Select messages needed for the pack cases from `rawData/{DISC}/`.
- Copy into:

  - Default: `ownScenarios/{DISC}/01_Schedule_Tile_Mixed_Day/`
  - Use `01_Schedule_Tile_Mixed_Days/` only when the sport truly needs multiple logical days (CKT-style).

- Prefer **one** simulation. Second folder only if the user asks or one day cannot hold conflicting states.

### 2. Remap dates

- Shared default **LogicalDate**: `2026-09-09` (align with other freezes).
- Extra days only when required (`2026-09-06` … etc.).
- Filename timestamps encode ingest order:

  `YYYY-MM-DD-HHMMSSmmm-DT_{TYPE}--{documentKey}.xml`

  Example: `2026-09-09-080000000-DT_PARTIC_UPDATE--ARC--------------------------------.xml`

### 3. Bootstrap (required)

| Condition | Messages (order) |
|-----------|------------------|
| Always | `DT_PARTIC` / `DT_PARTIC_UPDATE` |
| Teams present (`Type=T`) | then `DT_PARTIC_TEAMS[_UPDATE]` **and** `DT_ENTRIES` |
| Then | schedule / results / current / medallists / medals |

### 4. Timeline coverage (default: one simulation through medals)

| Phase | What must appear |
|-------|------------------|
| **Before** | `DT_SCHEDULE[_UPDATE]` — units SCHEDULED / pre-draw as per pack |
| **During** | Schedule → `RUNNING` (+ `INTERRUPTED` / break if in pack) + `DT_RESULT` and/or `DT_CURRENT` per pack |
| **After / target** | `FINISHED` + results; then **`DT_MEDALLISTS` → `DT_MEDALS`** (never reverse) |

Stop-points in README so playback can pause at “before only” or “mid-live”.

### 5. Schedule=S

If Common Codes (or the pack) lists units with `Schedule=S`, they **must** appear in schedule versions in the freeze so BE/FE can test:

- default list vs By Event visibility
- grouping / roll-up to phase (when grouping CSV or pack says so)

`S` is visibility/grouping — not a redirect change (unless the pack documents an RSC override).

### 6. Edge cases

Pack into **other events of the same discipline** in the same simulation (IRM, TBD/PreviousUnit, NOCOMP, W/O, live progress, medals on one event + live on another, …).  
Avoid a second scenario folder unless necessary.

### 7. Fabricate only when missing

After copy + remap:

- Fabricate only messages the playback still needs (e.g. RESULT / MEDALLISTS when raw dump is schedule-only).
- Keep competitor codes / team ids consistent with copied PARTIC.
- **Announce every fabricated file** to the user.
- Run ODF verifier on fabricated XML when practical; note results in README or the final reply.

### 8. Artefacts

#### `ownScenarios/{DISC}/README.md`

Must include:

- LogicalDate(s), Now after full ingest, folder name, ingest = filename order
- CC `@Unit` counts: **Y / N / S**
- Playback table (step, file prefix, message, now, what to check)
- Day / walkthrough map (RSC, status, expect)
- Redirects (CIS / WMR) per pack
- Sources in rawData (mapping table)
- **Fabricated files** section (list paths or `None`)
- Link to `AC.feature`

#### `ownScenarios/{DISC}/AC.feature`

Gherkin scenarios for key stop-points (before / mid / full ingest), referencing the scenario folder and LogicalDate — follow CRD/SQU style.

---

## Final reply (mandatory)

Always end with:

```
Fabricated:
- <path> — reason
- … or (none)
```

Also summarize: scenario path, LogicalDate, Schedule S units included, playback step count, verifier results on fabricated files.

---

## Definition of done

- [ ] Gate 0 passed (rawData used)
- [ ] ODFs copied then remapped (rawData untouched)
- [ ] PARTIC (+ TEAMS + ENTRIES if teams)
- [ ] Before / during / after through MEDALLISTS → MEDALS
- [ ] Schedule=S units included when CC has them
- [ ] README + AC.feature written
- [ ] Fabricated list printed (even if empty)
