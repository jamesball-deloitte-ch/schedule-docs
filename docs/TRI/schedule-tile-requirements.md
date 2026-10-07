# TRI Schedule Tile — Developer Requirements

**Scope:** Triathlon (`TRI`) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 (`OG2028_TRI_Live_Screens_R4_V1.0_20260312`) · ORIS LA28 R9 V1.1 (`OG2028_TRI_ORIS_R9_V1.1_20260220`) · ODF `OG2028-TRI-0.4` (+ GEN schedule `OG2028-GEN-5.2`) · SC/CC `OG2028` v1.6.0  
**RawData:** [`rawData/TRI`](../../rawData/TRI) (scenario folders + PT0 workbook).  
**Freeze:** [`ownScenarios/TRI`](../../ownScenarios/TRI) (`01_Schedule_Tile_Mixed_Day`, LogicalDate `2026-09-09`).

Flavour: **Event row + medallists after** (no live score on the schedule tile). Same family as CRD / CLB — not H2H.

---

## 1. TRI vs common

| Topic | TRI behaviour |
|-------|----------------|
| Events | Three medal events, each a single final unit: Women’s Individual `TRIWOLYMPIC`, Men’s Individual `TRIMOLYMPIC`, Mixed Relay `TRIXTEAM4` (ORIS §2.1 — finals only / in-line) |
| Tile type | **Event/unit row** — date, time, discipline + event name, status, medal marker |
| Results on tile | **N/A** (OSRP §1.2) — no race times, ranks, or H2H scores |
| Live | Status + live highlight when `RUNNING`. No `liveCurrentProgress` on the tile (`SC@Period` empty; OSRP does not ask for segment progress on schedule) |
| After | Show **all medallists** when known (individual → NOC + athlete; mixed relay → NOC + **team name**). Ties → more than three rows ([common §3.3.2](../common/schedule-tile-common.md)) |
| `competitors[]` | **Full** unit start list always ([common §3.3.1](../common/schedule-tile-common.md) — global NOC filter) |
| Placeholders | Only `NOAWARD` in `SC@CompetitorPlace` — not used for schedule opponents |
| `resultDecision` | **N/A** on schedule tile |
| Grouping | OSRP **N/A**. No row in `olympic-grouping-rules.csv` → **no `groupId`** |
| Schedule flag `S` | **None** (0 of 27 CC units). All phases `Schedule=N` |
| Which rows | The three competition finals (`Schedule=Y`, `Type` ATH/TEAM) + victory ceremonies on **CIS**. Omit DRAW / MEET / venue `OTHR` (non-competition). WMR drop of ceremonies is the shared BE filter ([common §3.1](../common/schedule-tile-common.md)) |
| Medal units | All three race units are `Medal=1` (gold event) — medal marker on the tile |

---

## 2. Situations (OSRP §1 + ORIS §3.1.6)

### 2.1 Before

- Date, start time, discipline + **event** name.
- Status indicators for any Triathlon schedule status. **Do not** show “Scheduled”.
- Medal-event marker (all three finals).
- **No** result / score / start-list block on the card UI.
- No H2H opponents or place-code placeholders on the tile.

### 2.2 During / after

While the race is in progress:

- Highlight / `liveFlag` when `scheduleStatus = RUNNING`.
- Still **no** results or segment progress on the schedule tile (detail lives on Start List / Results screens).

After the event is completed and medallists are known (OSRP §1.2):

| Event | Medallist rows |
|-------|----------------|
| Women’s / Men’s Individual | NOC (code and/or flag) + **athlete’s name** (+ medal icon per product) |
| Mixed Relay | NOC (code and/or flag) + **team name** (+ medal icon per product) |

Prefer `DT_MEDALLISTS` for who gets G/S/B on the tile. Do not invent medallists from a partial ranking. On shared medal places (ORIS §3.1.6.2.9), FE shows **every** medallist row — not capped at three ([common §3.3.2](../common/schedule-tile-common.md)).

### 2.3 Exceptional (ORIS §3.1.6)

Schedule-status matrix (shared chrome; ORIS wording = “race”):

| Status | Meaning (TRI) |
|--------|----------------|
| Delayed | Race does not start as scheduled but still within current ticketing session |
| Rescheduled | New date/time known within session (or later when known) |
| Postponed | Later session; new date/time unknown |
| Interrupted | Unplanned stop after start; may return to Running or escalate |
| Cancelled | Cannot be rescheduled before Closing Ceremony |

Competition-related (results / ORIS outputs — **not** separate schedule-tile chrome unless status changes):

- Format change to Duathlon / shortened course / invalid start (status stays `RUNNING` on invalid start).
- DNS / DNF / LAP / DSQ / DQB on athletes or teams (`SC@IRM`).
- Provisional results; photo-finish → Unconfirmed then Unofficial (ORIS results sequence).
- Shared medals on ties for medal places (ORIS §3.1.6.2.9) — tile shows all tied medallists (more than three rows when needed).

IRM catalogue (`SC@IRM`, OG2028): `DNF`, `DNS`, `DQB`, `DSQ`, `LAP`.

---

## 3. Backend — TRI

### 3.1 ODF sources

| Message | Role on schedule tile |
|---------|------------------------|
| `DT_SCHEDULE` / `DT_SCHEDULE_UPDATE` | Unit meta, times, venue, `ScheduleStatus`, medal flag, optional `StartText` — **GEN** message (not extended in TRI DD) |
| `DT_RESULT` `START_LIST` | Full unit start list → `competitors[]` for NOC filter (athletes `A` or teams `T`) — **not** rendered as scores on the card |
| `DT_RESULT` LIVE / INTERMEDIATE / UNOFFICIAL / OFFICIAL | Keep competitor set; IRMs / times feed results surfaces, not schedule scores |
| `DT_CURRENT` | Live race traffic while running — optional merge; **do not** map to tile score |
| `DT_MEDALLISTS` | Enrich finished unit: set `result.medal` on G/S/B (athletes or relay teams) |
| `DT_PARTIC` / `DT_PARTIC_TEAMS` | Names when schedule / result descriptions are thin |

### 3.2 Inclusion (Y + S rules)

Default list = competition units with CC `Schedule=Y`:

| RSC | Description | CC Schedule | Surfaces |
|-----|-------------|-------------|----------|
| `TRIWOLYMPIC-----------FNL-000100--` | Women’s Individual | Y | CIS + WMR |
| `TRIMOLYMPIC-----------FNL-000100--` | Men’s Individual | Y | CIS + WMR |
| `TRIXTEAM4-------------FNL-000100--` | Mixed Relay | Y | CIS + WMR |
| `TRIWOLYMPIC-----------VICTMEDAL---` | Women’s Victory Ceremony | Y | **CIS only** |
| `TRIMOLYMPIC-----------VICTMEDAL---` | Men’s Victory Ceremony | Y | **CIS only** |
| `TRIXTEAM4-------------VICTMEDAL---` | Mixed Relay Victory Ceremony | Y | **CIS only** |

Omit (even when `Schedule=Y`):

- All `TRIGGEN---------------DRAW*` (draws / athletes’ briefing & start position draw) — non-competition.
- All `TRIGGEN---------------MEET*` (managers’ meetings, course familiarisations) — meetings / non-competition.
- `TRIGGEN---------------OTHRVBH-----` — `Schedule=N` venue code.

No `Schedule=S` units (see §5). Phases (`…FNL---------`, `…VICT--------`, …) are all `Schedule=N` — not listed as tiles.

### 3.3 `competitors[]` + medallists

**Global** ([common §3.3.1](../common/schedule-tile-common.md)): load the unit start list from `DT_RESULT` (`ResultStatus = START_LIST` and later statuses). Keep the **full** list in `competitors[]` for country / NOC filter. Card UI does not show the peloton / team grid.

| Event | Competitor `@Type` |
|-------|--------------------|
| Individual finals | `A` |
| Mixed Relay | `T` (team name on `Description/@TeamName`) |

**After:** do **not** shrink the list to medallists-only. Overlay medals from `DT_MEDALLISTS` (`Medal/@Unit` = unit RSC):

```
DT_MEDALLISTS  (event DocumentCode)  +  Medal/@Unit = unit RSC
        │
        ▼
same competitors[ ]  (full start list retained)
  every medallist gets result.medal = GOLD | SILVER | BRONZE
  (ties → more than three athletes/teams with medal set)
```

Individual: medallist rows use athlete names. Mixed Relay: use **team** name (OSRP), not the four leg athletes as separate medallist lines.

### 3.4 Progress / decision fields

| Field | TRI schedule tile |
|-------|-------------------|
| `liveCurrentProgress` | **Omit** — OSRP Results/Scores N/A; `SC@Period` empty. Race segment codes exist under `SC@Segment` for results feeds, not for this tile |
| `resultDecision` | Omit |
| `placeholderOpponents` | Omit (no TBD bracket opponents) |
| `startText` | Common rules when `HideStartDate=Y` (GEN `StartText`; TRI has no `SC@StartText` codes — free text / pass-through) |

### 3.5 Backend checklist

- [ ] Emit three finals + CIS victory ceremonies; drop DRAW / MEET / OTHR  
- [ ] No false H2H scores or race times on the schedule payload used as “tile score”  
- [ ] `liveFlag` from `RUNNING`; clear progress fields (unused) on finish  
- [ ] Full `competitors[]` from unit `DT_RESULT` start list (global NOC filter); overlay `DT_MEDALLISTS` after  
- [ ] Mixed relay medallists expose **team** name + NOC; ties → all medallist rows  

- [ ] No `groupId`  
- [ ] No `Schedule=S` handling beyond “none”  

---

## 4. Frontend — TRI

**Results box (FE summary):** [schedule-tile-fe-score.md](./schedule-tile-fe-score.md) · AC: [ownScenarios/TRI/AC.feature](../../ownScenarios/TRI/AC.feature) · [DRES-32642](https://dgplatform.atlassian.net/browse/DRES-32642)

| Phase | FE |
|-------|-----|
| Before | Event title, time, venue, status / medal flag — **no** competitor / medallist / IRM block |
| During | Live highlight only; **no** result values |
| After | Medallists: **athletes** (individual) / **teams** (Mixed Relay); ties → all rows |
| Country filter | Show matching athletes or teams; **IRM only** on rows from the filtered NOC |

### 4.1 Grouping / visibility

- No grouping chrome (`groupId` absent).
- Render what the API returns; do not client-hide victory ceremonies on WMR (BE already filters).

### 4.2 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one unit-results URL for before / during / after**. `Schedule=S` does not apply; no RSC override documented for TRI.

Women’s Individual `TRIWOLYMPIC-----------FNL-000100--`:

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/TRI/W/OLYMPIC-----------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/triwolympic-----------fnl-000100--` |

Men’s Individual `TRIMOLYMPIC-----------FNL-000100--`:

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/TRI/M/OLYMPIC-----------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/trimolympic-----------fnl-000100--` |

Mixed Relay `TRIXTEAM4-------------FNL-000100--`:

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/TRI/X/TEAM4-------------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/trixteam4-------------fnl-000100--` |

In-app tabs after landing (Results / Summary / Race Facts, …) are not part of the schedule card href.

### 4.3 Frontend checklist

- [ ] Event-row layout; no H2H score rows  
- [ ] Live highlight only while in progress  
- [ ] After: all medallist rows (incl. ties) — athlete (individual) vs team name (relay)  
- [ ] No “Scheduled” badge  
- [ ] No `groupId` chrome  
- [ ] Card click → that unit’s results URL  

---

## 5. Schedule=S analysis

**Count: 0.** CC `@Unit` for TRI (`OG2028` v1.6.0) has **27** units: **26 × Y**, **1 × N**, **0 × S**. All **9** phases are `Schedule=N`.

`Schedule=S` is a visibility / grouping flag. It does not change the click target. There is no S unit to attach a different redirect to.

| RSC / pattern | CC Schedule | Default list | By Event | Expected grouping |
|---------------|-------------|--------------|----------|-------------------|
| `TRI*FNL-000100--` (W / M Individual, Mixed Relay) | Y | List (CIS and WMR) | List | No `groupId` |
| `TRI*VICTMEDAL---` | Y | CIS only | CIS only | BE omits from WMR |
| `TRIGGEN---------------DRAW*` | Y | Omit | Omit | Non-competition |
| `TRIGGEN---------------MEET*` | Y | Omit | Omit | Meetings / familiarisation |
| `TRIGGEN---------------OTHRVBH-----` | N | Omit | Omit | — |
| Any `*--------` phase RSC | N | Omit (not a tile) | Omit | — |
| — | S | — | — | No S units |

---

## 6. API gaps (TRI view)

| Gap | Why it is open |
|-----|----------------|
| `startText` | Needed when `HideStartDate=Y`. Same platform gap as common (Confluence has `hideStartDate` but not `startText`) |
| Segment progress on tile | ODF has leader `SC@Segment` on `DT_RESULT` ExtendedInfo for results; OSRP schedule says Results N/A — do **not** invent `liveCurrentProgress` unless product revises OSRP |

Decided (product): full `competitors[]` for NOC filter; non-H2H tied medallists → show all rows — see [common §3.3.1–3.3.2](../common/schedule-tile-common.md).

---

## 7. TRI cheat sheet

```
BEFORE:  DT_SCHEDULE (GEN) + DT_RESULT START_LIST
         →  meta/status/medalFlag + full competitors[] (NOC filter; not shown as scores)
         no groupId; no Schedule=S units
DURING:  + DT_CURRENT / DT_RESULT LIVE
         →  liveFlag only; no tile scores / no liveCurrentProgress
AFTER:   + DT_MEDALLISTS
         →  medal icons on all medallists (ties → >3 rows)
            individual: athlete name + NOC
            mixed relay: team name + NOC
         full competitors[] retained
```
