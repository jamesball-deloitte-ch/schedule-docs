# FBL Schedule Tile — Developer Requirements

**Scope:** Football (FBL) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 · ORIS LA28 R9 V1.1 · ODF `OG2028-FBL-0.2` · SC/CC `OG2028` v1.5.0  
**RawData:** Paris 2024 under `rawData/FBL`.

---

## 1. FBL vs common

| Topic | FBL behaviour |
|-------|----------------|
| Competitors | Teams only (`Type=T`) |
| Live progress | Match **period / game state** → `liveCurrentProgress` (§3.2) |
| `resultDecision` | **Required** for AET / PSO / Forfeit / Voided (§3.3) |
| Placeholders | `Competitor/@Code` ∈ `SC@CompetitorPlace` (`W25`, `A1`, `L29`, …) — Description is UI text |
| “Scheduled” badge | Not shown (common) |
| Score variants | Regular, AET, PSO+(parens), Forfeit, IRM |

---

## 2. Situations (OSRP §1.2 + ORIS §3.1.6)

### 2.1 Content

- Date, start time, event/phase, match number (unless hidden).
- Opponents: NOC + team name, or placeholder text from codes.
- Status: In Progress / Delayed / Finished / … — not “Scheduled”.
- Live: highlight In Progress.
- During: period + live score.
- After: winner, final score, AET / PSO / Forfeit / IRM indicators; medal symbol on medal matches.

### 2.2 Period labels (during)

| UI (full) | Abbr | `SC@Period` |
|-----------|------|-------------|
| First half | H1 | `H1` |
| Half-time | HT | `HT` |
| Second half | H2 | `H2` |
| First half of extra time | ET-H1 | `ET-H1` |
| Half-time of extra time | ET-HT | `ET-HT` |
| Second half of extra time | ET-H2 | `ET-H2` |
| Penalty shoot-out | PSO | `PSO` |

Also: `PET`, `PPSO`, `PKO`, `FT` / `RT` / `E-RT`, `TOT` as sent.

### 2.3 After-match patterns

| Situation | Indicator | ODF |
|-----------|-----------|-----|
| Regular | score only | no `RES_CODE` |
| Extra time | **AET** | `UI/RES_CODE = AET` |
| Penalties | **PSO** + `(n)` | `RES_CODE = PSO` + `Periods/Period[@Code='PSO']` |
| Forfeit | **Forfeit** | `RES_CODE = FORFEIT` |
| Voided | Void | `RES_CODE = VOIDED` |
| IRM | e.g. WDR | `Result/@IRM` (`ABD`, `DNS`, `DQB`, `DSQ`, `WDR`) |
| Winner | marker | `@WLT = W` |

### 2.4 Exceptional schedule

ORIS delay / postpone / interrupt / reschedule / cancel on **matches** — same codes as [common §2](../common/schedule-tile-common.md). After finish, status may move to Protested / Provisional.

---

## 3. Backend — FBL

Implements [common §3](../common/schedule-tile-common.md) plus below.

### 3.1 ODF messages

| Message | FBL tile role |
|---------|----------------|
| `DT_SCHEDULE[_UPDATE]` | Meta, status, teams / place codes |
| `DT_RESULT` | LIVE→OFFICIAL scores, `UI/PERIOD`, `UI/RES_CODE`, WLT, IRM |
| `DT_CURRENT` | High-frequency: `Clock/@Period` + scores while RUNNING |
| `DT_PARTIC_TEAMS` | Team display names if needed |

Do not require `DT_PLAY_BY_PLAY` / `DT_STATS` for the tile.

### 3.2 `liveCurrentProgress`

```
DT_CURRENT  Clock/@Period                         prefer while live
   or
DT_RESULT   ExtendedInfo[@Type='UI'][@Code='PERIOD']/@Value
        │
        ▼
SC@Period (FBL) Description
        │
        ▼
liveCurrentProgress.period.code / .name
(API may also send liveCurrentProgress.time — FE must not display it on the tile)
```

Populate only while live (`RUNNING` / in-match interrupt-break). Clear when finished.  
Confluence shape: `{ "period": { "code": "H1", "name": "First half" }, "time": "67:05" }` — tile uses **period only**.  
Example rawData: `Clock Period="H1"` / `ExtendedInfo … PERIOD Value="H1"` → period `{ "code": "H1", "name": "First half" }`.

### 3.3 `resultDecision` (proposed API)

```
DT_RESULT  ExtendedInfo[@Type='UI'][@Code='RES_CODE']/@Value
        │
        ▼
SC@ResultCode (FBL): AET | PSO | FORFEIT | VOIDED
        │
        ▼
resultDecision: { code, name }   // unit-level, not per competitor
```

Do **not** put IRMs here (`invalidResultMark` only).  
For `PSO`, also expose shoot-out tallies (proposed `psoResult` / `periodScores` from `Periods/Period[@Code='PSO']`).

> Confluence Schedule includes `resultDecision` (v24+) — required for OSRP after-state.

### 3.4 `startText`

Follow [common §3.4](../common/schedule-tile-common.md).  
`SC@StartText` (FBL): `TBD`, `TBC` (+ free text). Current FBL rawData schedule dump has little/no HideStartDate.

### 3.5 Placeholder opponents

`Competitor/@Code` is a **place code** when not a real team id (`FBLMTEAM11--FRA01`). Lookup **`SC@CompetitorPlace` Description** → `placeholderOpponents[].name` (FE renders as-is).

```
Competitor/@Code = "W25"
        → SC Description "Winner 25"
        → placeholderOpponents[{ name: "Winner 25", order }]
```

| `@Code` | Description (name) |
|---------|-------------------|
| `A1`…`D2` | `1A`, `2B`, … |
| `A3/B3`, `B3/C3` | `3A/3B`, `3B/3C` |
| `W19`…`W30` | `Winner 19`… |
| `L23`, `L24`, `L29`, `L30` | `Runner-up …` |
| `TBD` / `BYE` | To be determined / Bye |

**Worked example** (`5874-…-DT_SCHEDULE--FBL…~6~.xml`, SFNL): codes `W25`/`W27` → names `Winner 25`/`Winner 27`.  
When teams resolve, replace with `competitors[]` (`teamNames`).

(`DT_BRACKETS` may show `CompetitorPlace Code="TBD"` + `PreviousUnit` — schedule tile BE should prefer `DT_SCHEDULE` place codes.)

### 3.6 FBL backend checklist

Shared plus:

- [ ] `liveCurrentProgress` from Clock/PERIOD + `SC@Period`  
- [ ] Clear progress when not live  
- [ ] `resultDecision` from RES_CODE + `SC@ResultCode`  
- [ ] PSO paren scores when `PSO`  
- [ ] Place codes via `SC@CompetitorPlace` Description  

---

## 4. Frontend — FBL

**FE mapping (states + Schedule API fields):** [schedule-tile-fe.md](./schedule-tile-fe.md) · **Score / IRM / winner summary:** [schedule-tile-fe-score.md](./schedule-tile-fe-score.md)

Shared layout plus:

| Phase | FE |
|-------|-----|
| Before | `placeholderOpponents[].name` as-is |
| During | Period from `liveCurrentProgress.period.code` only; live score; **no** match clock; **no** winner marker |
| After | Score; winner (`WLT` only when finished); `resultDecision` indicator; IRM; PSO `(n)` via `psoResult` |

### 4.1 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one unit-results URL for before / during / after**.

Example unit RSC: `FBLMTEAM11------------GPA-000100--`

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/FBL/M/TEAM11------------/GPA-/000100--/results` |
| **WMR** | `/en/la28/results/unit/fblmteam11------------gpa-000100--` |

Destination is the FBL **Results** unit view (scoreboard / live match). Side rail (start-list, officials, …) and tabs (Groups, Bracket, …) are reached from that page, not from the schedule card href.

---

## 5. API gaps (FBL view)

Confluence Schedule (v24+) now includes `startText`, `resultDecision`, `psoResult`, and nested `liveCurrentProgress.period` + `.time` (FE ignores `.time` on the tile). Remaining FE/product questions: [schedule-tile-fe.md §10](./schedule-tile-fe.md).

| Field | Status |
|-------|--------|
| `resultDecision` | On Confluence — wire AET/PSO/FORFEIT/VOIDED |
| `psoResult` | On Confluence — paren shoot-out tallies |
| `startText` | On Confluence — when `hideStartDate` |
| `liveCurrentProgress` | On Confluence — implement §3.2 / FE §6 |

---

## 6. FBL cheat sheet

```
BEFORE:  DT_SCHEDULE  →  teams | SC@CompetitorPlace → placeholders
DURING:  + DT_RESULT/CURRENT  →  PERIOD/Clock → liveCurrentProgress, score
AFTER:   + DT_RESULT  →  score, WLT, IRM, RES_CODE → resultDecision, PSO periods
```
