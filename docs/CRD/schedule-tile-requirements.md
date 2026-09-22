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
| `DT_CURRENT` | Live race updates while `RUNNING` (Road Race) |
| `DT_RESULT` | Sparse while live; IRM / finish as applicable |
| `DT_MEDALLISTS` | **Enrich finished event tile** with G/S/B athletes |
| `DT_PARTIC` | Athlete names for medallists |

### 3.2 Medallists on tile (after)

Confluence schedule has `competitors[].result.medal`. For CRD after-state:

```
DT_MEDALLISTS  (event DocumentCode)
        │
        ▼
API schedules[] item for the event unit (or event-level row product chooses)
  competitors[ ] = three athletes
    type = "A"
    organisation / athleteNames
    result.medal = GOLD | SILVER | BRONZE
```

Do **not** invent medallists from partial `DT_RESULT` ranks unless product explicitly allows; prefer `DT_MEDALLISTS`.

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
- [ ] After finish: medallists from `DT_MEDALLISTS` on tile  
- [ ] Live driven by schedule status + `DT_CURRENT` availability  

---

## 4. Frontend — CRD

| Phase | FE |
|-------|-----|
| Before | Event title, time, venue, status/medal flag |
| During | Live highlight; **no result scores** |
| After | Up to three medallist rows (NOC + name + medal icon) |

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
BEFORE/DURING: DT_SCHEDULE (+ DT_CURRENT while RUNNING)  →  meta/status; no tile scores
AFTER:         DT_MEDALLISTS (+ PARTIC)                  →  G/S/B on tile
```
