# ARC Schedule Tile — Developer Requirements

**Scope:** Archery (ARC) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 (`OG2028_ARC_Live_Screens…`) · ORIS LA28 R9 V1.1 · ODF `OG2028-ARC-0.2` · SC/CC `OG2028` v1.5.0  
**RawData:** Paris 2024 ARC under `rawData/ARC` (schedule-heavy; little/no `DT_RESULT` in this dump).

---

## 1. ARC vs common

| Topic | ARC behaviour |
|-------|----------------|
| Competitors | Individuals `Type=A` **and** teams `Type=T` (team / mixed) |
| Live progress | **Current set** (or shoot-off), not football periods — see §3 |
| `resultDecision` | **Not used** for OSRP schedule samples (no AET/PSO/Forfeit); IRMs only |
| Placeholders | Mostly `TBD` + `PreviousUnit` / `PreviousWLT` on `Start`; also `NOCOMP` |
| BYE / unscheduled | Bye units in early rounds → **do not show** on schedule (`UNSCHEDULED`) |
| Time display | Special rule before opponents confirmed in elimination — §2 |
| Grouping | Match rounds may group by event; **medal matches not grouped** |
| Schedule flag `S` | Recurve team/mixed **qualification** concurrent with individual (`schedule=S`) — usually not displayed as normal tiles |

---

## 2. Situations (OSRP §1.2 + ORIS)

### 2.1 Before

- Date, start time, discipline / event / phase.
- Before competition started: names of event & phase; opponents when known.
- After qualification: as opponents for next phase become known, show athlete/team details.
- **Elimination — times before opponents confirmed:** show start time only for the **first phase of the day** (even if `DT_SCHEDULE` repeats the same time on later phases). If user filters by event, still show time for that day’s first phase.
- Matches with opponent **Bye** in first match-round phases: **omit** from schedule UI (`UNSCHEDULED`).
- Filter by event: list qualification unit for Team / Mixed Team when applicable (ODF may send `schedule=S`).

### 2.2 During / after (match rounds)

- Show **score** (set points); update after each set.
- After match: **winner** indicated (`WLT`).
- Regular:

```
Print Name / Team Name     n
Print Name / Team Name     n
```

- IRM:

```
Print Name / Team Name              n
Print Name / Team Name    IRM       n
```

or IRM on both sides when applicable.

- Medal matches: medal symbol on winners (`medalFlag` / result medal).

### 2.3 Exceptional (ORIS §3.1.6)

Same status family as common (Delayed / Postponed / Interrupted / Rescheduled / Cancelled) applied to **sessions/matches**. Extra ARC notes:

- Interrupted session: completed match results retained; incomplete matches normally resume.
- Athlete/team cannot contest next match → **DNS** on bracket/match; schedule (C58) updated; other matches in session may reschedule.
- IRMs: `DNS`, `DNF`, `DSQ`, `DQB` (`SC@IRM`).
- Provisional results possible (ORIS list of outputs + related feeds).

---

## 3. Backend — ARC

Implements [common §3](../common/schedule-tile-common.md) plus the following.

### 3.1 ODF sources

| Message | ARC use on tile |
|---------|-----------------|
| `DT_SCHEDULE[_UPDATE]` | Always — including TBD placeholders, HideStartDate, UNSCHEDULED bye units (filter out for UI list) |
| `DT_RESULT` | Match/qual scores (`SETS` / `POINTS`), WLT, IRM, `DISPLAY/CURRENT` set progress |
| `DT_CURRENT` | If sent — merge live; this rawData dump has little CURRENT |
| `DT_PARTIC` / `DT_PARTIC_TEAMS` | Athlete print names / team names |

### 3.2 `liveCurrentProgress` (ARC = current set)

Confluence field is documented as sport-specific (example FBL). For ARC map **current set / shoot-off**:

```
DT_RESULT  ExtendedInfo[@Type='DISPLAY'][@Code='CURRENT']
           @Pos = set number or "SO" (shoot-off)     (per ODF DD)
        │
        ▼
API  liveCurrentProgress.code = Pos or normalised "SO"
     liveCurrentProgress.name = "Set {n}" | "Shoot-off"
        │
        ▼
FE   optional compact progress on live tile
```

| When | API |
|------|-----|
| `RUNNING` + DISPLAY/CURRENT present | Set `liveCurrentProgress` |
| Qualification-only / not live / finished | `null` |

`SC@Period` for ARC is empty in COD — **do not** expect FBL-style `H1`/`HT` codes.

> OSRP schedule text stresses **score after each set**, not a long period label. Progress is secondary to score; still useful for CIS live scanning.

### 3.3 `resultDecision`

**N/A for ARC schedule tile.** No `SC@ResultCode` catalogue entries; OSRP after-state uses score + IRM + winner, not AET/PSO/Forfeit. Do not populate `resultDecision` for ARC.

### 3.4 `startText` / hide start

Follow [common §3.4](../common/schedule-tile-common.md).  
RawData shows `HideStartDate="Y"` on some `UNSCHEDULED` units **without** `StartText` — if such units were ever shown, still hide the clock. Prefer omitting `UNSCHEDULED` entirely (§2.1).

### 3.5 Placeholder opponents — ARC mapping

`SC@CompetitorPlace` (ARC): `BYE`, `TBD`, `NOCOMP`, `NOAWARD` (TBD Description is `-` — **not** usable as UI text).

#### Detection

| ODF | API |
|-----|-----|
| Real athlete/team code + org/name | `competitors[]` (`type` `A` or `T`; athleteNames / teamNames) |
| `Competitor/@Code = TBD` | `placeholderOpponents[]` — compose name from `Start/@PreviousWLT` + `@PreviousUnit` |
| `Code = NOCOMP` | Placeholder or empty side — name from SC Description **No competitor** |
| `Code = BYE` | Do **not** show unit on schedule (with `UNSCHEDULED`) |

#### TBD composition (preferred)

```
Start/@PreviousWLT = "W"|"L"
Start/@PreviousUnit = RSC of prior unit
        │
        ▼
Resolve prior Unit/@UnitNum (from schedule store)   e.g. 70
        │
        ▼
name = "Winner 70" | "Runner-up 70"     (W → Winner, L → Runner-up)
code = "TBD"   (optional on API)
```

Aligns with OSRP “Winner n / Runner-up n” wording used across sports.

#### Worked example (rawData)

File: `…/DT_SCHEDULE_UPDATE/607646-…~335~.xml`  
Unit `ARCMINDIVID-----------R32-000700--`:

```xml
<Start StartOrder="1" SortOrder="1">
  <Competitor Code="1562613" Type="A" Organisation="UZB">
    <Composition>
      <Athlete Code="1562613" Order="1" Bib="13">
        <Description GivenName="Amirkhon" FamilyName="Sadikov" … />
      </Athlete>
    </Composition>
  </Competitor>
</Start>
<Start StartOrder="2" SortOrder="2"
      PreviousWLT="W"
      PreviousUnit="ARCMINDIVID-----------R64-001400--">
  <Competitor Code="TBD" Type="A" />
</Start>
```

Prior unit `…R64-001400--` has `UnitNum="70"` in schedule.

API sketch:

```json
{
  "rsc": "ARCMINDIVID-----------R32-000700--",
  "competitors": [
    {
      "code": "1562613",
      "type": "A",
      "organisation": "UZB",
      "order": 1,
      "athleteNames": { "printName": "SADIKOV Amirkhon", "…": "…" }
    }
  ],
  "placeholderOpponents": [
    { "code": "TBD", "name": "Winner 70", "order": 2 }
  ]
}
```

Tile: **Sadikov (UZB)** vs **Winner 70**.

#### When opponent becomes known

Later schedule UPDATE replaces `TBD` with athlete/team id → move to `competitors[]`, clear placeholder for that `order`.

### 3.6 Score / result fields

| API | ODF (ARC) |
|-----|-----------|
| `competitors[].result.result` | Match set points or qual total (`Result/@Result`) |
| `resultType` | `SETS` (matches), `POINTS` (qual), `IRM` / `IRM_SETS` / … |
| `winLoseTie` | `@WLT` after match |
| `invalidResultMark` | `@IRM` (`DNS`, `DNF`, `DSQ`, `DQB`) |

### 3.7 Inclusion / filtering extras

- Emit `schedule=Y` units; handle `schedule=S` qual team/mixed per product (often hidden or only under event filter).
- Backend may still receive `UNSCHEDULED` bye units — **FE or BE filter** must drop them from schedule list (OSRP).
- Honour `hideUnitNum` when medal match details not yet confirmed (ODF).

### 3.8 ARC backend checklist

Shared checklist plus:

- [ ] TBD → `Winner {UnitNum}` / `Runner-up {UnitNum}` via Previous*  
- [ ] BYE / UNSCHEDULED units excluded from list payload or marked not displayable  
- [ ] Mixed known + TBD sides on same unit  
- [ ] `liveCurrentProgress` from `DISPLAY/CURRENT` while RUNNING (optional but recommended)  
- [ ] No `resultDecision` for ARC  
- [ ] Athlete vs team name blocks (`type` A/T)  

---

## 4. Frontend — ARC

**Score / IRM / winner (FE summary):** [schedule-tile-fe-score.md](./schedule-tile-fe-score.md)

Shared layout plus:

| Phase | FE |
|-------|-----|
| Before | Placeholders as BE `name`; apply **first-phase-of-day time** rule when opponents not confirmed; hide bye/unscheduled |
| During | Live highlight; score; optional set progress from `liveCurrentProgress` |
| After | Final score; winner; IRM layout per OSRP; medal icon on medal matches |
| Grouping | Allow group-by-event for match rounds; **do not group** medal matches |

### 4.1 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one unit-results URL for before / during / after**. Bye / `UNSCHEDULED` units are not listed, so they have no click target.

Example unit RSC: `ARCMINDIVID-----------FNL-000100--`

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/ARC/M/INDIVID-----------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/arcmindivid-----------fnl-000100--` |

Team / mixed units use the same patterns with their event slots (e.g. `TEAM3-------------`, `TEAM---------------`). Bracket tab is in-app after landing on Results — not the schedule card href.

---

## 5. API gaps (ARC view)

| Field | ARC need |
|-------|----------|
| `startText` | Yes if any visible HideStartDate units |
| `resultDecision` | **No** |
| `liveCurrentProgress` | Yes if showing current set (map from `DISPLAY/CURRENT`, not FBL PERIOD) |
| Placeholder `code` | Optional (`TBD`) — `name` mandatory |

---

## 6. ARC cheat sheet

```
BEFORE:  DT_SCHEDULE  →  meta, A|T competitors | TBD+Previous* → Winner n
         filter out UNSCHEDULED/BYE
DURING:  + DT_RESULT  →  SETS score, DISPLAY/CURRENT → liveCurrentProgress
AFTER:   + DT_RESULT  →  score, WLT, IRM, medal
```
