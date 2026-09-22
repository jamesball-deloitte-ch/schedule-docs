# SQU Schedule Tile — Developer Requirements

**Scope:** Squash (SQU) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 · ORIS LA28 R9 V1.1 · ODF SQU LA28 · SC/CC `OG2028` v1.5.0  
**RawData:** none in this repo.

---

## 1. SQU vs common

| Topic | SQU behaviour |
|-------|----------------|
| Tile type | **Head-to-head match** (individuals, `Type=A`) |
| Before draw | Event/phase only — no opponents |
| After draw | First phase: unit + opponent names; later phases: phase name until opponents known |
| During / after | **Game score**; winner; IRMs |
| Live progress | Current **game** `G1`…`G5` → `liveCurrentProgress` |
| `resultDecision` | Useful for `W/O`, `RET`, double IRMs (`SC@ResultCode`) |
| Placeholders | `BYE`, `NOCOMP`, `NOWINNER`, + `PreviousUnit` / bracket position text |

---

## 2. Situations (OSRP §1)

### 2.1 Before competition, before the Draw

- Date, time, discipline, event, phase.
- Status / medal indicators (not “Scheduled”).
- No opponents.

### 2.2 Before competition, after the Draw

- **First phase:** discipline, event, **unit name with opponents’ names**.
- **Later phases:** discipline, event, phase name (opponents later).

### 2.3 During / after

- As opponents for next phase known → names or **bracket position**.
- Score during and after; **winner** after match.
- Regular:

```
Print Name                         n
Print Name                         n
```

- IRM:

```
Print Name                         n
Print Name            IRM     n
```

- Medal matches: medal symbol on winner.

### 2.4 Exceptional (ORIS §3.1.6.1)

Common OC statuses (Squash IF wording differs; use OC codes). Interrupt → postpone / reschedule / cancel.

---

## 3. Backend — SQU

### 3.1 ODF sources

| Message | Role |
|---------|------|
| `DT_SCHEDULE[_UPDATE]` | Meta, status, start list, `PreviousUnit`, place codes |
| `DT_RESULT` | LIVE/OFFICIAL scores (`SETS`/points), WLT, IRM, game periods, RES_CODE |
| `DT_CURRENT` | If sent — live merge |
| `DT_PARTIC` | Print names |
| `DT_BRACKETS` | Optional context for bracket positions |

### 3.2 `liveCurrentProgress`

```
DT_RESULT  UI/PERIOD or current Period[@Code] ∈ {G1…G5}
        │
        ▼
SC@Period  G1="Game 1" … G5="Game 5"  (TOT = Match Total — not “current game”)
        │
        ▼
liveCurrentProgress { code: "G2", name: "Game 2" }
```

Set while `RUNNING`; clear when finished.

### 3.3 Scores / WLT / IRM

| API | ODF |
|-----|-----|
| `competitors[].result.result` | Match games won (or points — follow `ResultType`) |
| `winLoseTie` | `@WLT` after match |
| `invalidResultMark` | `@IRM`: `DSQ`, `DQB`, `RET`, `W/O` |

### 3.4 `resultDecision` (recommended for SQU)

```
UI/RES_CODE or ResultCode  →  SC@ResultCode
```

| Code | Description |
|------|-------------|
| `W/O` | Walkover |
| `RET` | Retired |
| `2W/O` | Double Walkover |
| `2RET` | Double Retirement |
| `2DSQ` | Double Disqualification |

Use for tile indicators when both sides IRM / walkover cases; still set per-competitor `invalidResultMark` when applicable.

### 3.5 Placeholder opponents

`SC@CompetitorPlace`: `BYE`, `NOCOMP`, `NOAWARD`, `NOWINNER`.

Also compose from schedule when opponent unknown:

```
PreviousUnit/@WLT + @Unit  and/or Competitor/@Code place indicator
        →  placeholderOpponents[].name
```

OSRP allows **bracket position** text when names not yet known — resolve via PreviousUnit / bracket codes (same idea as ARC Winner *n*).  
`BYE`: follow product (often hide or show Bye — confirm vs ARC hide-unscheduled).

**Before draw:** leave `competitors` / placeholders empty; show phase only.

### 3.6 `startText`

Common §3.4 when `HideStartDate=Y` (StartText exists in SQU DD).

### 3.7 SQU checklist

- [ ] Before-draw vs after-draw payload shapes  
- [ ] H2H scores + winner  
- [ ] `liveCurrentProgress` from G1–G5  
- [ ] IRM + optional `resultDecision` for W/O/RET/doubles  
- [ ] Placeholders / bracket position / PreviousUnit  
- [ ] Medal icon on medal-match winner  

---

## 4. Frontend — SQU

| Phase | FE |
|-------|-----|
| Before draw | Event/phase only |
| After draw | Opponents when present; else phase |
| During | Live + game progress + score |
| After | Score, winner, IRM / decision indicators, medal |

### 4.1 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one unit-results URL for before / during / after** (including before-draw tiles that show phase only).

Example unit RSC: `SQUMSINGLES-----------FNL-000100--`

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/SQU/M/SINGLES-----------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/squmsingles-----------fnl-000100--` |

Women’s singles and earlier rounds (`8FNL`, `QFNL`, …) use the same builders with their RSC. Bracket / Ranking are section tabs reached after landing on the unit view — not the schedule card href.

---

## 5. Cheat sheet

```
BEFORE DRAW:  DT_SCHEDULE           →  meta only
AFTER DRAW:   DT_SCHEDULE           →  opponents | placeholders
DURING:       + DT_RESULT           →  G1–G5 progress, live score
AFTER:        + DT_RESULT           →  score, WLT, IRM, RES_CODE
```
