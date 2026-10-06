# SQU Schedule Tile — Developer Requirements

**Scope:** Squash (SQU) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**FE results box:** [schedule-tile-fe-score.md](./schedule-tile-fe-score.md)  
**Editions:** OSRP LA28 R4 V1.0 · ORIS LA28 R9 V1.1 · ODF SQU LA28 · SC/CC `OG2028` v1.6.0  
**Freeze:** [ownScenarios/SQU](../../ownScenarios/SQU/README.md)

---

## 1. SQU vs common

| Topic | SQU behaviour |
|-------|----------------|
| Tile type | **Head-to-head match** (individuals, `Type=A`) |
| Before draw | Event/phase only — no opponents |
| After draw | First phase: unit + opponent names; later phases: phase name until opponents known |
| During / after | **Game score**; winner; IRMs; live highlight |
| `liveCurrentProgress` | **Not on schedule tile** — OSRP §1.4 has no current-game chrome (do not copy FBL `H1`→`G3`) |
| `resultDecision` | **Not on schedule tile** — OSRP §1.4 is score + row IRM only (do not copy FBL) |
| Placeholders | **Mixed only** (one known + one unknown). `name` as in ODF (`TBD`). Do **not** compose `Winner n` |

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

- When **both** opponents for the next phase are known → names.
- When **one** is known → known name + placeholder (`TBD`).
- When **neither** is known → phase/event only (empty `competitors` and `placeholderOpponents`). Product: do **not** emit dual `Winner n` / dual `TBD` rows. OSRP mentions “bracket position”; we do not map that string on the tile.
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
| `DT_RESULT` | LIVE/OFFICIAL scores (`SETS`/points), WLT, IRM |
| `DT_CURRENT` | If sent — live merge (score / IRM / status only for the tile) |
| `DT_PARTIC` | Print names |

### 3.2 `liveCurrentProgress` — **out of scope for the schedule tile**

ODF `UI/PERIOD` / `SC@Period` (`G1`…`G5`, `TOT`) feeds **Start List / Results** (OSRP §2 — highlight current game). Do not map to schedule-tile `liveCurrentProgress`. Tile live = `liveFlag` + games-won score.

### 3.3 Scores / WLT / IRM

| API | ODF |
|-----|-----|
| `competitors[].result.result` | Match games won (or points — follow `ResultType`) |
| `winLoseTie` | `@WLT` after match |
| `invalidResultMark` | `@IRM`: `DSQ`, `DQB`, `RET`, `W/O` |

### 3.4 `resultDecision` — **out of scope for the schedule tile**

ODF `UI/RES_CODE` / `SC@ResultCode` (`W/O`, `RET`, `2W/O`, `2RET`, `2DSQ`) exists for **results outputs**, not for CIS/WMR schedule chrome.

ORIS §3.1.6.2.6 **No winner** specifies **C73 / C74A / C74B / C75**. That is not an OSRP schedule-card layout and must not be mapped as FBL-style `resultDecision` on the tile.

Schedule tile: per-competitor `@IRM` → `invalidResultMark` only.

### 3.5 Placeholder opponents

Emit `placeholderOpponents[]` **only** when exactly one start-list side is a known athlete and the other is not (`TBD` / empty / place without a person).

| Start list | API |
|------------|-----|
| Two athletes | `competitors[]` only |
| One athlete + unknown | One competitor + one placeholder; `name` = feed value (expect **`TBD`**) |
| Two unknown | **Neither** array — unit still listed; card is phase/event only |

Do **not** map `PreviousUnit` / UnitNum / bracket codes to `Winner n`. Keep `PreviousUnit` on the payload if the API already has it for other consumers; do not use it to invent a display name.

`SC@CompetitorPlace` (`BYE`, `NOCOMP`, `NOAWARD`, `NOWINNER`) stays as competitor/place codes when that is what ODF sent — not as composed bracket copy.

**Before draw:** leave `competitors` / placeholders empty; show phase only.

### 3.6 `startText`

Common §3.4 when `HideStartDate=Y` (StartText exists in SQU DD).

### 3.7 SQU checklist

- [ ] Before-draw vs after-draw payload shapes  
- [ ] H2H scores + winner  
- [ ] No tile `liveCurrentProgress`  
- [ ] IRM on the competitor (`invalidResultMark`); no tile `resultDecision`  
- [ ] Placeholder only for mixed known/unknown; name not composed  
- [ ] Medal icon on medal-match winner  

---

## 4. Frontend — SQU

| Phase | FE |
|-------|-----|
| Before draw | Event/phase only |
| After draw | Opponents when both known; mixed `TBD` placeholder; else phase |
| During | Live highlight + score |
| After | Score, winner, IRM, medal |

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
AFTER DRAW:   DT_SCHEDULE           →  both names | mixed TBD | meta only
DURING:       + DT_RESULT           →  live highlight, score
AFTER:        + DT_RESULT           →  score, WLT, IRM
```

---

## 6. Open product questions

- **ORIS C73 “No winner” copy on the schedule card?** Not specified in OSRP. Default: **omit** (row IRMs only). Do not invent a `2DSQ` / `Not played (Double …)` band from FBL `resultDecision`.
- **OSRP “bracket position” vs `TBD`:** OSRP §1 allows bracket-position text; product default for this tile is **do not compose** it — show feed `TBD` only in the mixed case.
