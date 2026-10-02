# CRD Schedule Tile — Developer Requirements

**Scope:** Cycling Road (CRD) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 · ORIS LA28 R9 · ODF `OG2028-CRD-0.4` (approx.) · SC/CC `OG2028` v1.5.0  
**RawData:** [`rawData/CRD/01_CRD_PT1_HappyPath`](../../rawData/CRD/01_CRD_PT1_HappyPath), [`rawData/CRD/02_CRD_PT1_Exceptionals`](../../rawData/CRD/02_CRD_PT1_Exceptionals). Freeze: [`ownScenarios/CRD`](../../ownScenarios/CRD).

---

## 1. CRD vs common

| Topic | CRD behaviour |
|-------|----------------|
| Tile type | **Event/phase unit** (road race / time trial) — not H2H match card |
| Results on tile | **N/A** during competition (OSRP) |
| Live | Status + live highlight; race progress via **`DT_CURRENT`** (ODF: while LIVE, `DT_RESULT` usually not sent unless IRM) |
| After | Show **medallists** (NOC + athlete + medal icon) once known |
| Placeholders | Minimal (`NOAWARD` only in `SC@CompetitorPlace`) |
| `liveCurrentProgress` | Not football-style PERIOD (`SC@Period` empty). Optional product mapping from `DT_CURRENT` if exposed |
| `resultDecision` | **N/A** for schedule tile |

---

## 2. Situations (OSRP §1)

### 2.1 Before / during

- Date, start time, discipline + **event** name.
- Status indicators (not “Scheduled”); live highlight when `RUNNING`.
- Medal-event marker when applicable.
- **No score / result block** on the schedule tile.

### 2.2 After event completed

When medallists are known (often `DT_MEDALLISTS` UNOFFICIAL before full official ranking — ODF timeline):

- Show medallists: **NOC (code/flag) + athlete name + medal icon** (G/S/B).

### 2.3 Exceptional

Common delay / postpone / interrupt / reschedule / cancel. IRMs on results feeds (`DNF`, `DNS`, `DSQ`, `DQB`, `OTL`) — not typically rendered as H2H score on this tile.

---

## 3. Backend — CRD

### 3.1 ODF sources

| Message | Role on schedule tile |
|---------|------------------------|
| `DT_SCHEDULE[_UPDATE]` | Unit meta, times, status, medal flag |
| `DT_RESULT` `START_LIST` | **Full unit start list** → `competitors[]` (all riders; required for country / NOC filter) |
| `DT_RESULT` LIVE / UNOFFICIAL / OFFICIAL | Keep / update the same competitor set (+ IRM / finish as applicable) |
| `DT_CURRENT` | Live race updates while `RUNNING` (Road Race) — not the start-list source |
| `DT_MEDALLISTS` | **Enrich** finished unit: set `result.medal` on the three athletes **inside** the full list |
| `DT_PARTIC` | Athlete names |
| `DT_ENTRIES` | Optional event-level entries; **does not** replace unit `DT_RESULT` START_LIST |

### 3.2 Full `competitors[]` (all phases) + medallists (after)

**Product:** every competition unit tile must carry the **complete** start-list in `competitors[]` (hidden on the card UI). Country filter matches a tile when any `competitors[].organisation` equals the selected NOC.

```
DT_RESULT  DocumentCode = <unit RSC>   ResultStatus = START_LIST
        │
        ▼
API schedules[] item for that unit
  competitors[ ] = ALL start-list athletes (type = "A")
    organisation / athleteNames / order (StartSortOrder)
```

Required for **each** of the four FNL units: `CRDWTT…FNL-000100--`, `CRDMTT…FNL-000100--`, `CRDWRR…FNL-000100--`, `CRDMRR…FNL-000100--`.

After the unit is finished, **do not shrink** the list to three medallists. Overlay medals from `DT_MEDALLISTS` (`Medal/@Unit` = unit RSC):

```
DT_MEDALLISTS  (event DocumentCode)  +  Medal/@Unit = unit RSC
        │
        ▼
same competitors[ ] (full list)
  three athletes get result.medal = GOLD | SILVER | BRONZE
```

Do **not** invent medallists from partial `DT_RESULT` ranks unless product explicitly allows; prefer `DT_MEDALLISTS` for medal icons.

### 3.3 Progress / decision fields

| Field | CRD |
|-------|-----|
| `liveCurrentProgress` | Optional — only if BE maps a clear CURRENT-derived code/name; else omit |
| `resultDecision` | Omit |
| `placeholderOpponents` | Rare; `NOAWARD` if used |
| `startText` | Common rules when `HideStartDate=Y` |

### 3.4 CRD checklist

- [ ] Schedule Y units with status/liveFlag  
- [ ] No false H2H scores on tile  
- [ ] Each FNL unit has **full** `competitors[]` from `DT_RESULT` START_LIST (country filter)  
- [ ] After finish: keep full list; set `result.medal` from `DT_MEDALLISTS` on G/S/B only  
- [ ] Live driven by schedule status + `DT_CURRENT` availability  

---

## 4. Frontend — CRD

**Results box (FE summary):** [schedule-tile-fe-score.md](./schedule-tile-fe-score.md)

| Phase | FE |
|-------|-----|
| Before | Event title, time, venue, status/medal flag — **do not render** the full start list on the card |
| During | Live highlight; **no result scores**; full list stays for filter only |
| After | Up to three medallist rows (`result.medal` set) — still do not render the whole peloton |

### 4.1 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one unit-results URL for before / during / after** (event unit, not H2H match).

Example unit RSC: `CRDMRR----------------FNL-000100--` (men’s road race final)

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/CRD/M/RR----------------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/crdmrr----------------fnl-000100--` |

Same pattern for women / time trial (`CRDWRR…`, `CRDMTT…`, `CRDWTT…`). In-app tabs after landing: Results / Summary (or Groups of riders / Pretiming per event) — not part of the schedule card href. Legacy compact LA28 CRD URLs redirect into `/results/unit/{rsc}`.

---

## 5. Cheat sheet

```
BEFORE:  DT_SCHEDULE + DT_RESULT START_LIST  →  meta/status + full competitors[] (filter)
DURING:  + DT_CURRENT / DT_RESULT LIVE       →  live highlight; keep full competitors[]
AFTER:   + DT_MEDALLISTS                     →  medal icons on 3 of N; list stays full
```