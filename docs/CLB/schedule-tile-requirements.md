# CLB Schedule Tile — Developer Requirements

**Scope:** Sport Climbing (CLB) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 · ORIS LA28 R9 · ODF CLB LA28 · SC/CC `OG2028` v1.5.0  
**RawData:** Paris-style dump under `rawData/CLB`.  
**Test freeze:** [own_scenarios/CLB](../../own_scenarios/CLB/README.md) (`01_Schedule_Tile_Mixed_Day`, LogicalDate `2026-09-09`)

---

## 1. CLB vs common

| Topic | CLB behaviour |
|-------|----------------|
| Tile type | **Phase/unit session** (Boulder/Lead) or Speed heat/phase — not always H2H score card |
| Results on tile | **N/A** (OSRP schedule) |
| After | Show **three medallists** (NOC + athlete) when known |
| Placeholders | Rich `SC@CompetitorPlace`: `TBD`, `WQF*`, `WSF*`, `LSF*`, `BYE`, `NOCOMP` |
| `liveCurrentProgress` | **N/A** for schedule tile (`SC@Period` empty); live = status highlight |
| `resultDecision` | **N/A** on schedule tile |
| Schedule flags | Boulder/Lead: unit `Y`; Speed: mix of phase `Y` + race `S` (ODF) |

---

## 2. Situations (OSRP §1)

### 2.1 Before / during

- Date, start time, discipline, event, phase.
- Status / medal indicators (not “Scheduled”); live highlight when `RUNNING`.
- **No result scores** on the schedule tile.
- When bracket opponents known for a unit: may show names or place-code text (Speed / finals context) — still no climbing score on this tile.

### 2.2 After event completed

- Show **three medallists**: NOC (code/flag) + athlete name (+ medal icon per product).

### 2.3 Speed schedule granularity (ODF)

| Stage | Schedule inclusion |
|-------|-------------------|
| Boulder / Lead | Units with `schedule=Y` |
| Speed qual seeding | Single unit |
| Speed qual elimination | Heats `Y`; each race also `S` |
| Speed finals | Phase `Y`; each pair unit also `S` |

Product must decide which RSC rows appear as tiles (prefer `Y`; `S` may be detail-only).

---

## 3. Backend — CLB

### 3.1 ODF sources

| Message | Role |
|---------|------|
| `DT_SCHEDULE[_UPDATE]` | Meta, status, medal flag, start list / place codes |
| `DT_RESULT` | Unit results (not shown as schedule score per OSRP) |
| `DT_BRACKETS` | Finals bracket context |
| `DT_MEDALLISTS` | **Enrich finished event** with G/S/B |
| `DT_PARTIC` | Names |

### 3.2 Medallists on tile (after)

Same pattern as CRD:

```
DT_MEDALLISTS → schedules[] competitors[]
  type=A, athleteNames, organisation, result.medal = GOLD|SILVER|BRONZE
```

### 3.3 Placeholder opponents (when unit has bracket sides)

`SC@CompetitorPlace` → `placeholderOpponents[].name` (Description):

| Code | Description |
|------|-------------|
| `TBD` | To be defined |
| `WQF1`…`WQF4` | Winner of Quarterfinal 1…4 |
| `WSF1`, `WSF2` | Winner of Semifinal 1/2 |
| `LSF1`, `LSF2` | Loser of Semifinal 1/2 |
| `BYE` | Bye |
| `NOCOMP` | Not competed |

Known athletes → `competitors[]` (`Type=A`).

### 3.4 Progress / decision

| Field | CLB schedule tile |
|-------|-------------------|
| `liveCurrentProgress` | Omit (or only if product invents non-PERIOD progress — not in OSRP schedule) |
| `resultDecision` | Omit |
| `startText` | Common rules if HideStartDate used (StartText not in CLB batch hit — confirm per DD version) |

### 3.5 Inclusion

- Default list: `schedule=Y` units/phases.
- Document Speed `S` races as optional / filtered (avoid flooding schedule with every pair if phase row already shown).

### 3.6 CLB checklist

- [ ] Y (and agreed S) units in payload  
- [ ] No climbing scores on schedule tile  
- [ ] Place codes WQF/WSF/LSF/TBD resolved via SC Description  
- [ ] After: three medallists from `DT_MEDALLISTS`  
- [ ] Live = `scheduleStatus` / `liveFlag` only  

---

## 4. Frontend — CLB

| Phase | FE |
|-------|-----|
| Before | Event/phase, time, placeholders if bracket sides unknown |
| During | Live highlight; no result block |
| After | Three medallist rows |

### 4.1 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one unit-results URL for before / during / after**.

Example unit RSC: `CLBMSPEED-------------FNL-000100--`

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/CLB/M/SPEED-------------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/clbmspeed-------------fnl-000100--` |

Boulder / Lead / earlier Speed heats use the same patterns (`BOULDER-----------`, `LEAD--------------`, `QFNL…`, …). Qualifications Summary / Summary tabs are in-app after Results — not the schedule card href.

---

## 5. Cheat sheet

```
BEFORE/DURING: DT_SCHEDULE  →  meta/status; optional WQF/WSF placeholders; no scores
AFTER:         DT_MEDALLISTS →  three medallists on tile
SPEED:         prefer schedule=Y rows; treat schedule=S as secondary
```
