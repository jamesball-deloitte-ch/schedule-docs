# FBL Schedule Tile — Frontend Mapping

**Audience:** Frontend (WMR / CIS schedule card)  
**Product / BE rules:** [schedule-tile-requirements.md](./schedule-tile-requirements.md) · [common](../common/schedule-tile-common.md)  
**Score / IRM / winner only:** [schedule-tile-fe-score.md](./schedule-tile-fe-score.md)  
**API contract:** [SCDLA Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule) (`{competitionCode}/schedule`, SSE + HTTP; day filter `schedulesPerDay/{YYYY-MM-DD}`)  
**UX source:** OSRP FBL Competition Schedule §1.2 (LA28 R4 V1.0)

**Document versions:** OSRP `OG2028_FBL_Live_Screens` R4 V1.0 · SC/CC `OG2028` v1.6.0 · Confluence Schedule page v24 (2026-09-15) · ODF pack refs `OG2028-FBL-0.2`

Flavour: **H2H + score** (teams only, `competitors[].type = "T"`). Reuse the baseline schedule card; extend score / progress / decision rendering for FBL — do not fork a football-only layout unless design ships one.

---

## 1. Card anatomy → API fields

```
┌──────────────────────────────────────────────────────────────────┐
│ [time]     Headline (discipline)              Full Results  …   │
│ [status]   Subtext (event / phase / match #)                    │
│ [medal?]   optional live progress                               │
├──────────────────────────────────────────────────────────────────┤
│  Results box (2 rows)                                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 🏳️ Team A                         score (+ PSO / IRM)    │◀──│ winner
│  │ 🏳️ Team B                         score (+ PSO / IRM)    │   │
│  └────────────────────────────────────────────────────────────┘ │
│  Decision strip (AET / PSO / Forfeit / Voided) — when present   │
└──────────────────────────────────────────────────────────────────┘
```

| UI slot | API field(s) | Notes |
|---------|--------------|-------|
| Time | `startDate` **or** `startText` | If `hideStartDate === true` → show `startText` (never format clock from `startDate`). If hide + null `startText` → still hide clock. |
| End (rarely on card) | `endDate` / `hideEndDate` | Usually not on compact tile |
| Live highlight | `liveFlag` | Prefer `true` when `scheduleStatus === "RUNNING"`; emphasize row/card |
| Status badge | `scheduleStatus` + `scheduleStatusDescription` | **Before finish.** Never show badge for `SCHEDULED`. Prefer OSRP labels where they differ from CC (e.g. Running → **In Progress**). |
| Status after finish | `resultStatus` + `resultStatusDescription` | When `scheduleStatus === "FINISHED"` |
| Live period | `liveCurrentProgress.period.code` | During only; clear when not live. **For now display `code` only** (`H1`, `HT`, …). Ignore `period.name` and `liveCurrentProgress.time`. |
| Discipline | `disciplineName` (fallback `discipline`) | Headline |
| Event / phase | `eventName`, `phaseName` | Subtext; may also use `unitName` |
| Match number | `unitNumber` | Omit when `hideUnitNum === true` |
| Venue (if shown) | `venueDescription` / `locationDescription` | Prefer long forms only if layout allows |
| Medal marker | `medalFlag` | `"1"` gold, `"3"` bronze, `"0"` / absent = none |
| Team rows | `competitors[]` | Confirmed teams |
| Placeholder rows | `placeholderOpponents[]` | Before opponents known — render `name` as-is |
| Score | `competitors[].result.result` | Main score string/number |
| Winner | `competitors[].result.winLoseTie` | `"W"` → chevron + bold name **only when** `scheduleStatus === "FINISHED"` |
| IRM | `competitors[].result.invalidResultMark` | e.g. `WDR` |
| PSO paren | `competitors[].result.psoResult` | After / during PSO → `(n)` beside score |
| Decision indicator | `resultDecision.code` / `.name` | AET / PSO / FORFEIT / VOIDED |
| Click target | `rsc` (+ optional `overrideRsc`) | Unit results href — same URL before/during/after ([common §4.3](../common/schedule-tile-common.md)) |

**Not used on FBL schedule tile:** `athleteNames`, `extendedResultInfo.finalResultDescription` (CKT), individual `type: "A"` rows, `liveCurrentProgress.time` (match clock).

---

## 2. State machine (when to show what)

Derive **phase** from `scheduleStatus` first; after `FINISHED`, prefer `resultStatus` for the badge.

```
SCHEDULED / GETTING_READY / DELAYED / RESCHEDULED / POSTPONED / CANCELLED
        → BEFORE (or exceptional before-start)
RUNNING / INTERRUPTED / SCHEDULED_BREAK
        → DURING
FINISHED (+ resultStatus)
        → AFTER
UNSCHEDULED
        → do not list on schedule UI
```

### 2.1 Schedule status → FE

| `scheduleStatus` | Badge / label | Scores | Progress | Notes |
|------------------|---------------|--------|----------|-------|
| `SCHEDULED` | **No badge** | No | No | OSRP: “Scheduled” not needed |
| `GETTING_READY` | Getting Ready | No | No | Pre-kick-off |
| `DELAYED` | Delayed | No | No | Still before start |
| `RESCHEDULED` | Rescheduled | No | No | New `startDate` / `startText` from API |
| `POSTPONED` | Postponed | No | No | New time unknown |
| `CANCELLED` | Cancelled | No | No | Will not be played |
| `RUNNING` | **In Progress** | Yes (live) | Yes | `liveFlag` true; highlight |
| `INTERRUPTED` | Interrupted | Keep last | Keep / clear per last SSE | Match started |
| `SCHEDULED_BREAK` | Scheduled Break | Keep | Period may be HT / ET-HT | Planned break |
| `FINISHED` | → use `resultStatus` | Final | **Clear** progress | See §2.2 |
| `UNSCHEDULED` | — | — | — | Filter out |

Use `scheduleStatusDescription` as the default human string when showing a badge, except:

- `SCHEDULED` → suppress entirely  
- `RUNNING` → prefer **In Progress** (OSRP) over CC “Running”

### 2.2 Result status → FE (only when finished)

| `resultStatus` | Badge |
|----------------|-------|
| `UNOFFICIAL` | Unofficial |
| `OFFICIAL` | Official (or hide if product treats finished+official as silent) |
| `PROTESTED` | Protested |
| `PROVISIONAL` | Provisional |
| `UNCONFIRMED` | Unconfirmed |
| `LIVE` / `INTERMEDIATE` / `START_LIST` / `PARTIAL` | Unusual on finished tile — if present, show description as-is |

---

## 3. Phase → slot matrix

| Slot | Before | During | After |
|------|--------|--------|-------|
| Time / `startText` | ✓ | ✓ | Optional (status often dominates) |
| Status badge | Exceptional only; never Scheduled | In Progress / Interrupted / Break | From `resultStatus` |
| `liveFlag` styling | Off | On when live | Off |
| `liveCurrentProgress` | Hidden | `period.code` only | Hidden / ignore stale |
| Headline / subtext | Discipline + event/phase + match # | Same | Same |
| Medal | If `medalFlag` ∈ {1,3} | Same | Same (+ winner medal on row if API sets `result.medal`) |
| Rows | Teams **or** placeholders; **no scores** | Flags + names + live score | Flags + names + final score |
| PSO `(n)` | — | If in PSO and `psoResult` set | If `resultDecision.code === "PSO"` |
| `resultDecision` | — | Rare (usually after) | AET / PSO / Forfeit / Voided indicator |
| Winner chevron | — | **Never** | When `winLoseTie === "W"` |
| IRM | — | If sent | Yes |
| Card click | Unit results | Same RSC | Same RSC |

---

## 4. Competitors vs placeholders

| Condition | Source | FE |
|-----------|--------|-----|
| Confirmed teams | `competitors[]` | Flag from `organisation`; name from `teamNames.name` (fallback `shortName` / `tvTeamName` per DS) |
| Opponents TBD | `placeholderOpponents[]` | No NOC flag (or DS placeholder glyph); **`name` as-is** (`Winner 25`, `1A`, …) |
| Both sides | Prefer competitors when present for that `order`; placeholders only for missing side | Do not invent TBD copy on FE |

Order rows by `order` ascending (home/away or start order as BE sends).

```ts
// Illustrative — align with existing Schedule types
type FblRow = {
  order: number;
  organisation?: string;      // NOC for flag
  name: string;               // teamNames.name | placeholderOpponents.name
  isPlaceholder: boolean;
  score?: string | null;      // result.result
  psoParen?: number | null;   // result.psoResult → "(n)"
  irm?: string | null;        // result.invalidResultMark
  isWinner?: boolean;         // only if FINISHED && winLoseTie === "W"
  medal?: string | null;      // result.medal
};
```

---

## 5. Score & decision rendering (OSRP patterns)

### 5.1 Regular

```
Team Name        n
Team Name        n
```

| API | UI |
|-----|-----|
| `result.result` | Score `n` |
| no `resultDecision` | No decision strip |
| `winLoseTie === "W"` + `FINISHED` | Winner styling (never during) |

### 5.2 After Extra Time (`resultDecision.code === "AET"`)

```
Team Name        AET    n
Team Name               n
```

Show decision label from `resultDecision.name` (“After Extra Time”) or short **AET** per space.

### 5.3 Penalty shoot-out (`resultDecision.code === "PSO"`)

```
Team Name        n   PSO
                     (n)
Team Name        n
                     (n)
```

| API | UI |
|-----|-----|
| `result.result` | Main score (goals in match) |
| `result.psoResult` | Parenthetical shoot-out tallies |
| `resultDecision` | **PSO** indicator |

If `psoResult` missing while `code === "PSO"` → still show PSO label; leave `(n)` empty / hide paren (do not invent).

### 5.4 Forfeit (`resultDecision.code === "FORFEIT"`)

```
Team Name     Forfeit    n
Team Name                n
```

Prefer `resultDecision.name` (“Victory by Forfeit”) or short **Forfeit**.

### 5.5 Voided (`resultDecision.code === "VOIDED"`)

Show void indicator from `resultDecision`; scores if present.

### 5.6 IRM

```
Team Name              n
Team Name     WDR      n   // invalidResultMark
```

IRM is **per competitor** (`invalidResultMark`). Do **not** put IRM into `resultDecision`.

---

## 6. Live progress (FBL-specific)

Confluence may send (sports like FBL):

```json
"liveCurrentProgress": {
  "period": { "code": "H1", "name": "First half" },
  "time": "67:05"
}
```

| Field | FE |
|-------|-----|
| `period.code` | **Display this** (current rule) — `H1`, `HT`, `H2`, `ET-H1`, `ET-HT`, `ET-H2`, `PSO`, … |
| `period.name` | Ignore for now |
| `time` | **Do not show** |

OSRP abbreviations (what `code` values mean):

| Code | Full (OSRP; not shown yet) | Abbr on tile |
|------|----------------------------|--------------|
| `H1` | First half | H1 |
| `HT` | Half-time | HT |
| `H2` | Second half | H2 |
| `ET-H1` | First half of extra time | ET-H1 |
| `ET-HT` | Half-time of extra time | ET-HT |
| `ET-H2` | Second half of extra time | ET-H2 |
| `PSO` | Penalty shoot-out | PSO |

Also possible from feed/codes: `PET`, `PPSO`, `PKO`, `FT`, `RT`, `E-RT`, `TOT` — still render the **`code`** as-is when present.

**Rules**

1. Show only while during (`RUNNING` / interrupt / scheduled break) and object non-null.  
2. On `FINISHED` or before start: ignore stale progress.  
3. Place period beside status or under start time — **one** place, not duplicated.  
4. Never render `liveCurrentProgress.time` on the schedule tile.  
5. Do not use `period.name` until product switches to full labels / space-allows rule.

---

## 7. Full field map (Schedule item → FE)

| API field | Before | During | After | FE action |
|-----------|:------:|:------:|:-----:|-----------|
| `rsc` | ✓ | ✓ | ✓ | Build unit-results href; prefer `overrideRsc` when non-empty |
| `overrideRsc` | ✓ | ✓ | ✓ | Redirect override list (Confluence) |
| `discipline` / `disciplineName` | ✓ | ✓ | ✓ | Headline |
| `gender` | ○ | ○ | ○ | Rarely on card |
| `event` / `eventName` | ✓ | ✓ | ✓ | Subtext |
| `phase` / `phaseName` / `phaseCode` | ✓ | ✓ | ✓ | Subtext |
| `unitName` | ○ | ○ | ○ | Alt subtext if event+phase thin |
| `unitNumber` / `hideUnitNum` | ✓ | ✓ | ✓ | Match # unless hidden |
| `sessionCode` | ○ | ○ | ○ | Filters / grouping chrome if any |
| `startDate` / `hideStartDate` / `startText` | ✓ | ✓ | ○ | Time slot rules §1 |
| `endDate` / `hideEndDate` | ○ | ○ | ○ | Usually off-card |
| `dateOrder` | ○ | ○ | ○ | Sort only |
| `liveFlag` | | ✓ | | Live styling |
| `scheduleStatus` (+ Description) | ✓ | ✓ | gate | §2.1 |
| `liveCurrentProgress` | | ✓ | | `period.code` only — §6 |
| `liveCurrentProgress.period.name` | — | — | — | Ignore for now |
| `liveCurrentProgress.time` | — | — | — | **Ignore** (no match clock) |
| `resultStatus` (+ Description) | | ○ | ✓ | §2.2 |
| `venue*` / `location*` | ○ | ○ | ○ | If layout shows where |
| `medalFlag` | ✓ | ✓ | ✓ | Medal icon |
| `competitors[]` | ✓ | ✓ | ✓ | Rows |
| `competitors[].teamNames.*` | ✓ | ✓ | ✓ | Display name |
| `competitors[].organisation*` | ✓ | ✓ | ✓ | Flag / NOC |
| `competitors[].result.result` | | ✓ | ✓ | Score |
| `competitors[].result.winLoseTie` | | — | ✓ | Winner chevron **only after** `FINISHED` |
| `competitors[].result.invalidResultMark` | | ○ | ✓ | IRM |
| `competitors[].result.psoResult` | | ○ | ✓ | `(n)` |
| `competitors[].result.medal` | | | ✓ | Row medal if distinct from unit `medalFlag` |
| `competitors[].result.resultType` / `position` | ○ | ○ | ○ | Not primary on FBL tile |
| `placeholderOpponents[]` | ✓ | | | TBD rows |
| `resultDecision` | | ○ | ✓ | AET/PSO/Forfeit/Voided |
| `extendedResultInfo` | — | — | — | **Ignore** for FBL |

✓ = primary · ○ = optional / secondary · blank = hide

---

## 8. Click redirects

Same as [common §4.3](../common/schedule-tile-common.md) and [FBL pack §4.1](./schedule-tile-requirements.md): **one** unit-results URL for all phases.

Example RSC: `FBLMTEAM11------------GPA-000100--`

| Surface | Href |
|---------|------|
| CIS | `/en/OG2028/FBL/M/TEAM11------------/GPA-/000100--/results` |
| WMR | `/en/la28/results/unit/fblmteam11------------gpa-000100--` |

If `overrideRsc` is set, build the path from the override (see Confluence Schedule RSC overrides page).

---

## 9. FE checklist

- [ ] Map Schedule JSON fields per §7; no client ODF parsing  
- [ ] Never show “Scheduled” badge  
- [ ] Before: placeholders from BE `name`; no scores  
- [ ] During: live highlight + score + `liveCurrentProgress.period.code` only (no `.name`, no `.time`)  
- [ ] After: final score, winner (`WLT` only when `FINISHED`), IRM, `resultDecision`, PSO `(psoResult)`  
- [ ] No winner chevron / bold-winner while during  
- [ ] Clear stale live progress when finished  
- [ ] `hideStartDate` → `startText` (or blank), never raw start clock  
- [ ] Teams via `teamNames`; `type === "T"`  
- [ ] Medal from `medalFlag`  
- [ ] Card click → unit results; same URL before/during/after  
- [ ] WMR may hide medal-ceremony-only units client-side; CIS keeps them  

---

## 10. Open product questions

1. **Official badge** — After finish + `OFFICIAL`, show “Official” or rely on Finished → silence?  
2. **Decision placement** — Dedicated strip vs inline next to score (OSRP samples show inline AET/PSO/Forfeit)?  

**Decided:** no match clock (`liveCurrentProgress.time` ignored); live period shows **`period.code` only** for now; winner indicator only when `scheduleStatus === "FINISHED"`. Default for the rest: show non-Scheduled badges from API descriptions; render decision **inline** as in OSRP samples.
