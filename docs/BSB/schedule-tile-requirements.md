# BSB Schedule Tile — Developer Requirements

**Scope:** Baseball/Softball (`BSB`) only — men’s Baseball and women’s Softball in one discipline.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 (`OG2028_BSB_Live_Screens_R4_V1.0_20260710`) · ORIS LA28 R9 V1.2 (`OG2028_BSB_ORIS_R9_V1.2_20260914_APP`) · ODF `OG2028-BSB-0.3` · SC/CC `OG2028` v1.6.0  
**RawData:** none in this repo.  
**Freeze:** none (`ownScenarios/BSB` not present).

Flavour: **H2H + score** (team game card). Not an event-row / medallists tile.

---

## 1. BSB vs common

| Topic | BSB behaviour |
|-------|----------------|
| Events | Two team events under one discipline: Baseball `BSBMBBLTEAM9` (M) and Softball `BSBWSBLTEAM9` (W). Same tile rules; different place codes and regulation length |
| Competitors | Teams only (`Competitor/@Type = T`). Visitor `StartOrder`/`SortOrder` **1**, home **2** |
| Live progress | **Top / Bottom of the current inning**, not a period name from `SC@Period` (“Inning n”) |
| Score | Runs (`Result/@Result`, `POINTS` or `IRM_POINTS`). Updated after each run. No inning-by-inning line score on the tile |
| `resultDecision` / Forfeit | OSRP shows **(Forfeit)** on a score row. ODF has **no** `UI/RES_CODE` (and no `FORFEIT` text). `SC@ResultCode` is only `FORFEIT`, with no XPath. Do not infer forfeit from 9–0 / 7–0 |
| IRM on the row | `DSQ`, `DQB`, `SUS` (`SC@IRM`) beside that team’s score |
| Placeholders | `SC@CompetitorPlace` on `Competitor/@Code`. OSRP names only **TBD**, **Semifinal Loser**, **Semifinal Winner**. CC has more codes — display string is unresolved (§6) |
| BYE | `BYE` exists in the place catalogue. No CC unit is a bye game, and OSRP does not say to hide a game |
| Grouping | OSRP **N/A**. No row in `olympic-grouping-rules.csv` → **no `groupId`** |
| Schedule flag `S` | **None** (0 of 36 CC units). Phases are all `Schedule=N` |
| Which rows | Competition games only, plus victory ceremonies on **CIS**. No official-training units in CC. Meetings are never a tile. WMR drop of ceremonies is the shared BE filter ([common §3.1](../common/schedule-tile-common.md)) |
| Medal games | Gold / bronze **games** carry the medal symbol on the **winner**. Those games stay on CIS and WMR |

---

## 2. Situations (OSRP §1.2 + ORIS §2 / §3.1.6)

### 2.1 Before

- Date, start time, discipline, phase name, game number (or blank when the number is not available / hidden).
- Status indicators for any Baseball/Softball schedule status. **Do not** show “Scheduled”.
- Medal-event marker on gold and bronze games.
- Opponents when confirmed: **NOC (code and/or flag) + team name**.
- Before opponents are confirmed, OSRP §1.2 says:
  - **TBD** for every game except the bronze and gold medal games
  - **Semifinal Loser** on the bronze medal game
  - **Semifinal Winner** on the gold medal game
- CC place codes are richer than that sentence (group ranks, quarterfinal winner). Which string the tile shows is an open question (§6). Do **not** compose ARC-style “Winner {UnitNum}” from `PreviousUnit`.

Competition shape (ORIS §2), for context only — the tile is still one game:

| Event | Games (all `Schedule=Y`) |
|-------|--------------------------|
| Baseball | Group A (3), Group B (3), quarterfinals (2), semifinals (2), gold + bronze |
| Softball | One group, 15 games, then gold + bronze (no quarterfinal / semifinal units) |

### 2.2 During / after

While the game is in progress:

- Highlight / live flag.
- Current half-inning: **Top n** or **Bottom n** (OSRP §1.2 spells the second label “Botton”; OSRP §2 and the ODF extension use **Bottom**. Use **Bottom**).
- Score (runs) for each team, updated after each run scored.

After the game:

- Final score and **winner**.
- Medal symbol on the winner of a medal game.

Regular:

```
Team Name     n
Team Name     n
```

Forfeit (OSRP sample; which row carries the label is not stated — §6):

```
Team Name     n   (Forfeit)
Team Name     n
```

IRM:

```
Team Name           n
Team Name    IRM    n
```

OSRP §1 does **not** ask for balls, strikes, outs, batter, pitcher, or the inning line score. Those belong on the game screen (OSRP §2), not this tile.

### 2.3 Exceptional (ORIS §3.1.6)

OC schedule-status words apply (ORIS notes that WBSC wording differs). Same family as common, applied to a **game**:

| Status | ORIS rule (summary) |
|--------|---------------------|
| Delayed | Will start inside the current ticketing session. Within 15 minutes and no new time → stay Delayed until Running. New time inside the session → Rescheduled, then Running |
| Postponed | Did not start, or an interrupted game that is not yet a regulation game cannot resume in this session, and the new date/time are unknown. Later Rescheduled or Cancelled |
| Interrupted | Interruption **before** the game is a regulation game, resumption time unknown. Resume from the same point when it continues. If it cannot finish in this session → Postponed, Rescheduled, or Cancelled |
| Rescheduled | New date and start time are known |
| Cancelled | Cannot be rescheduled before the Closing Ceremony |

Sport notes that are **not** a second tile layout unless §6 is decided:

- **Regulation game:** five innings complete (four and a half if the home team is leading). Until then, an interruption does not lock tournament statistics.
- **No Game:** an interrupted game that never becomes a regulation game and cannot be resumed. No `SC@IRM` / `SC@ResultCode` value for this. Tile treatment is open (§6).
- **Forfeit:** score reported as **9–0** (Baseball) or **7–0** (Softball) to the team that wins by forfeit, plus a note. A played game can finish with the same score, so the score alone is not a forfeit detector. OSRP still wants a **(Forfeit)** indicator (§6).
- **Team DSQ / withdrawal in the group stage:** that team’s group games are reissued as forfeit losses (0–9 Baseball, 0–7 Softball). In the Baseball knockout stage, the next or most recently completed knockout game is a forfeit loss (0–9).
- **IRM meanings (ORIS):** `DSQ` = breach of WBSC rules; `DQB` = Olympic Charter / anti-doping / other serious breach. `SUS` is in `SC@IRM` (“Suspended”); ORIS §3.1.6.2.7 uses suspension for a **player** on the line-up, not as a documented game-score mark (§6).
- **Provisional:** results status Provisional when a decision is pending (IOC, CAS, WBSC, or another body).
- **Extra innings:** if tied after the regulation length, play on. The tile keeps Top n / Bottom n; it does not switch to a separate “extra innings” code. `SC@Period` runs `1`…`18`.

---

## 3. Backend — BSB

Implements [common §3](../common/schedule-tile-common.md) plus the following.

### 3.1 ODF sources

| Message | BSB use on the tile |
|---------|---------------------|
| `DT_SCHEDULE` / `DT_SCHEDULE_UPDATE` | Identity, time, venue, status, medal, `UnitNum`, start list / place codes, `StartText` |
| `DT_RESULT` | Runs, `WLT`, `IRM`, `UI/PERIOD` + half-inning. Triggers: `LIVE` at the start of each inning and after each data change; `INTERMEDIATE` after each half-inning; `UNOFFICIAL` / `OFFICIAL` / `PROVISIONAL` when the unit ends. **Remove `UI/PERIOD` when official** |
| `DT_CURRENT` | Same `UI/PERIOD` + `HALF` if sent between result messages. Also carries batter, pitcher, last pitch, balls, strikes, outs, baserunners — **do not** map those onto the tile |
| `DT_PARTIC_TEAMS` | Team names when the schedule description is thin |

`DT_RESULT` does not define `UI/RES_CODE`. Grep of the BSB Data Dictionary and GEN for `RES_CODE` and `FORFEIT` returned no hits.

### 3.2 Inclusion (Y + S rules)

Follow [common §3.1](../common/schedule-tile-common.md): tiles are **competition units** and **official trainings** only. BSB CC has **no** official-training unit, so the game list below is the full competition set.

- Do **not** list phase rows. Every BSB phase in CC is `Schedule=N`.
- Do **not** list `Schedule=N` units: `BSBGGEN---------------OTHRDGR-----`, `BSBGGEN---------------OTHROSP-----`.
- **`Schedule=S`:** no BSB unit. Nothing to nest or roll up (§5).
- **Meetings** (`MEET000100--`, `MEET000200--`, `MEET000300--`) are `Schedule=Y` and are **not** tiles on CIS or WMR.
- **Victory ceremonies** (`BSBMBBLTEAM9----------VICTMEDAL---`, `BSBWSBLTEAM9----------VICTMEDAL---`): include for **CIS**, omit for **WMR**. Same backend filter as every other discipline — not a BSB special case, and not an FE hide.

Game units to list (all `Type=HTEAM`, `Schedule=Y`):

| Pattern | Event | Count | Medal on unit |
|---------|-------|-------|----------------|
| `BSBMBBLTEAM9----------GPA-000100--` … `000300--` | Baseball Group A | 3 | 0 |
| `BSBMBBLTEAM9----------GPB-000100--` … `000300--` | Baseball Group B | 3 | 0 |
| `BSBMBBLTEAM9----------QFNL000100--`, `000200--` | Quarterfinals | 2 | 0 |
| `BSBMBBLTEAM9----------SFNL000100--`, `000200--` | Semifinals | 2 | 0 |
| `BSBMBBLTEAM9----------FNL-000100--` | Gold medal game | 1 | 1 |
| `BSBMBBLTEAM9----------FNL-000200--` | Bronze medal game | 1 | 3 |
| `BSBWSBLTEAM9----------GP--000100--` … `001500--` | Softball group | 15 | 0 |
| `BSBWSBLTEAM9----------FNL-000100--` / `000200--` | Softball gold / bronze | 2 | 1 / 3 |

CC descriptions for opening-round units repeat “Baseball Opening Round” / “Softball Opening Round” and do not carry a distinct game number. Game number on the tile comes from `Unit/@UnitNum` unless `HideUnitNum` is set.

### 3.3 `liveCurrentProgress` (current half-inning)

`SC@Period` descriptions are “Inning 1” … “Inning 18”. OSRP wants **Top n** / **Bottom n**. Build the label from the half extension, not from the period description.

```
DT_RESULT or DT_CURRENT
  ExtendedInfo[@Type='UI'][@Code='PERIOD']/@Value     SC@Period  ("1"…"18")
  Extension[@Code='HALF']/@Value                      "T" | "B"
        │
        ▼
API  liveCurrentProgress.period.code = Value          e.g. "2"
     liveCurrentProgress.period.name = "Top 2" | "Bottom 2"
        │
        ▼
FE   compact progress on the live tile only
```

ODF sample (`OG2028-BSB-0.3`):

```xml
<ExtendedInfo Type="UI" Code="PERIOD" Value="2">
  <Extension Code="HALF" Value="T" />
</ExtendedInfo>
```

→ `period.name = "Top 2"`.

| When | API |
|------|-----|
| Schedule status in progress (`RUNNING`) and `UI/PERIOD` is present | Set `liveCurrentProgress` |
| `HALF` missing | Do not invent Top vs Bottom; leave `name` unset and surface the gap |
| Not in progress, or `UI/PERIOD` removed (ODF: remove when official) | `null` |

Do not send match clock, balls, strikes, or outs on this field.

### 3.4 `resultDecision` / Forfeit

**Do not populate `resultDecision` from a guessed XPath.**

| Source | What it says |
|--------|----------------|
| OSRP §1.2 | A **(Forfeit)** indicator on a score row, separate from the IRM row |
| `SC@ResultCode` | Single code `FORFEIT` / “Forfeit” |
| ODF `OG2028-BSB-0.3` | No `ExtendedInfo[@Type='UI'][@Code='RES_CODE']`, no `FORFEIT` element |
| ORIS §3.1.6.2.1.2 | Printed score 9–0 or 7–0 plus a note. Not unique to forfeits |

IRM stays on `competitors[].result.invalidResultMark` only.

### 3.5 `startText` / hide start

Follow [common §3.4](../common/schedule-tile-common.md).  
`SC@StartText`: `TBD`, `TBC`.  
ODF: in team sports, `HideStartDate="Y"` is used temporarily to suppress a time. When it is set, the tile shows `startText` (or nothing), not the clock.

### 3.6 Placeholder opponents

Detection on `DT_SCHEDULE` `StartList/Start/Competitor/@Code` (format includes `SC@CompetitorPlace`):

| ODF | API |
|-----|-----|
| Real team id + organisation / team name | `competitors[]` (`type` `T`, `organisation`, `teamNames`), `order` from `SortOrder` / `StartOrder` |
| Code in `SC@CompetitorPlace` | `placeholderOpponents[]` with that `code` and the same `order` |

Row order is the ODF order: **1 = visitor, 2 = home**. Tile totals come from each `Result/@Result`. Do not rebuild the score from `Periods/Period/@HomeScore` (that description calls the home side the “first named” competitor, which does not match `StartOrder` 1 = visitor). Line-score periods are not the tile.

`PreviousUnit` is present only while the real team is unknown:

- `@Unit` — RSC of the source unit, and only when progression is confirmed; removed once the team is known
- `@Value` — pool or match number (`SC@Pool` or `S(15)`). If `HideUnitNum=Y`, do not disclose that number

OSRP does not ask for a “Winner of game n” string. Do not build the placeholder `name` from `@Unit` / `@Value` the way Archery builds “Winner {UnitNum}”.

`SC@CompetitorPlace` (what the feed can send) vs OSRP §1.2 (what the sample shows):

| Code | CC description | Note | OSRP §1.2 sample |
|------|----------------|------|------------------|
| `TBD` | To be determined | | **TBD** (every non-medal game) |
| `LSF` | Semifinal Loser | | **Semifinal Loser** (bronze) |
| `WSF` | Semifinal Winner | | **Semifinal Winner** (gold) |
| `WQF` | Quarterfinal Winner | | not named (OSRP says TBD) |
| `A1` `A2` `A3` `B1` `B2` `B3` | same as the code | For Baseball | not named (OSRP says TBD) |
| `1A` `2A` `3A` `4A` | 1st…4th in Group Stage | For Softball | not named (OSRP says TBD) |
| `BYE` | Bye | | not described |
| `NOCOMP` | No competitor | | not described |

`SC@Pool` (`1` / `2` / `3` = 1st / 2nd / 3rd in Pool) is the catalogue for `PreviousUnit/@Value`, not a second competitor-place list.

**`name` is not specified** when CC and OSRP disagree. Emit `code`. Leave `name` to the product decision in §6. Agreed cases, if product follows OSRP literals where they exist: `LSF` → “Semifinal Loser”, `WSF` → “Semifinal Winner”. Even `TBD` disagrees (`TBD` vs “To be determined”).

When a later schedule update replaces the place code with a team id, move that side to `competitors[]` and drop the placeholder.

### 3.7 Score / winner / medal

| API | ODF |
|-----|-----|
| `competitors[].result.result` | `Result/@Result` (runs, `##0`) |
| `resultType` | `POINTS` or `IRM_POINTS` (`SC@ResultType`) |
| `winLoseTie` | `Result/@WLT`. Team values used on the tile are **W** / **L**. `S` (Save) is the pitcher statistic `StatsItem[@Code='PITCH_RESULT']`, not the team row |
| `invalidResultMark` | `Result/@IRM`: `DSQ`, `DQB`, `SUS` |
| `medalFlag` | `Unit/@Medal`: `1` gold game, `3` bronze game, `0` otherwise |
| Winner medal icon | OSRP: medal symbol on the **winner** of a medal game. Use `medalFlag` ∈ {1, 3} and `WLT=W`. This tile does not switch to an event-row medallists list |

`DT_RESULT` statuses the tile must accept: `START_LIST`, `LIVE`, `INTERMEDIATE`, `UNOFFICIAL`, `OFFICIAL`, `PROVISIONAL`.

### 3.8 Backend checklist

Shared checklist plus:

- [ ] Visitor order 1, home order 2; score from `Result/@Result` per team
- [ ] Place code → `placeholderOpponents[].code`; do not invent `name` where §6 is open
- [ ] Do not compose placeholder text from `PreviousUnit`
- [ ] `liveCurrentProgress.period` from `UI/PERIOD` + `HALF` while `RUNNING`; clear when absent / not in progress
- [ ] Do not map `DT_CURRENT` balls / strikes / outs / batter / pitcher onto the tile
- [ ] No `resultDecision` until a Forfeit XPath exists
- [ ] IRM on the team (`DSQ` / `DQB` / `SUS`); pitcher `S` is not team `WLT`
- [ ] List the game units in §3.2; omit meetings; victory ceremonies on CIS only (shared BE filter)
- [ ] No `groupId` (no CSV row)

---

## 4. Frontend — BSB

Shared layout plus:

| Phase | FE |
|-------|-----|
| Before | NOC + team name, or placeholder `name` once §6 chooses it. No score. No “Scheduled” badge. Game number unless hidden |
| During | Live highlight. Runs. **Top n** / **Bottom n** from `liveCurrentProgress.period.name`. No line score, count, or pitcher |
| After | Final runs, winner (`WLT` W/L), IRM on that row, medal icon on the winner of a medal game. No half-inning label |
| Forfeit | Show **(Forfeit)** only when the API actually carries it. Do not paint it because the score is 9–0 or 7–0 |
| Exceptional | Delayed, Rescheduled, Postponed, Interrupted, Cancelled, Provisional as in common. Keep the last runs. Live highlight only while `liveFlag` |

### 4.1 Grouping / visibility

- OSRP Grouping = **N/A**.
- `docs/grouping/olympic-grouping-rules.csv` has **no `BSB` row** → units have no `groupId`. Do not group medal games, group-stage games, or sessions unless a CSV row is added later.
- Omit `UNSCHEDULED` units if any arrive (common). OSRP does not define a bye-hide rule for a listed game.
- Baseball vs Softball is an **event** filter (`BBLTEAM9` / `SBLTEAM9`), not two disciplines.

### 4.2 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one unit-results URL** for before, during, after, and exceptional statuses. `Schedule=S` does not apply. Meetings are not listed. A CIS victory-ceremony tile, when present, still opens that ceremony unit’s results RSC. FE does not drop ceremonies; WMR never receives them.

Baseball gold medal game `BSBMBBLTEAM9----------FNL-000100--`:

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/BSB/M/BBLTEAM9----------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/bsbmbbteam9----------fnl-000100--` |

Softball bronze medal game `BSBWSBLTEAM9----------FNL-000200--`:

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/BSB/W/SBLTEAM9----------/FNL-/000200--/results` |
| **WMR** | `/en/la28/results/unit/bsbwsblteam9----------fnl-000200--` |

Group, quarterfinal, and semifinal games use the same builders with their own RSC. Play-by-play, box score, and bracket stay in-app after landing on Results.

### 4.3 Frontend checklist

- [ ] H2H team rows in visitor/home order
- [ ] Live half-inning label only while in progress
- [ ] Score is total runs, not a line score
- [ ] Winner and row IRM after the game; medal icon on the medal-game winner
- [ ] No Forfeit label without an API field
- [ ] No `groupId` chrome
- [ ] Card click → that unit’s results URL

---

## 5. Schedule=S analysis

**Count: 0.** CC `@Unit` for BSB (`OG2028` v1.6.0) has 36 units: **34 × Y**, **2 × N**, **0 × S**. All 12 phases are `Schedule=N`.

`Schedule=S` is a visibility / grouping flag. It does not change the click target. There is no S unit to attach a different redirect to.

| RSC / pattern | CC Schedule | Default list | By Event | Expected grouping |
|---------------|-------------|--------------|----------|-------------------|
| Game units in §3.2 (Baseball GPA/GPB/QFNL/SFNL/FNL, Softball GP/FNL) | Y | List (CIS and WMR) | List | No `groupId` |
| `BSBGGEN---------------MEET000100--` Baseball managers’ meeting | Y | Omit | Omit | Not a competition unit or official training |
| `BSBGGEN---------------MEET000200--` Softball managers’ meeting | Y | Omit | Omit | Same |
| `BSBGGEN---------------MEET000300--` Baseball/Softball managers’ meeting | Y | Omit | Omit | Same |
| `BSBMBBLTEAM9----------VICTMEDAL---` Baseball victory ceremony | Y | CIS only | CIS only | BE omits from WMR |
| `BSBWSBLTEAM9----------VICTMEDAL---` Softball victory ceremony | Y | CIS only | CIS only | BE omits from WMR |
| `BSBGGEN---------------OTHRDGR-----`, `…OTHROSP-----` | N | Omit | Omit | — |
| Any `*--------` phase RSC | N | Omit (not a tile) | Omit | — |
| — | S | — | — | No S units |

---

## 6. API gaps (BSB view)

| Gap | Why it is open |
|-----|----------------|
| Forfeit indicator | OSRP requires **(Forfeit)**. `SC@ResultCode=FORFEIT` has no Data Dictionary XPath. 9–0 / 7–0 is not a detector |
| Placeholder `name` | OSRP §1.2 literals vs `SC@CompetitorPlace` descriptions disagree except as a partial overlap on LSF/WSF |
| No Game | ORIS name for an interrupted game that never resumes and never becomes a regulation game. No IRM or result code |
| `SUS` on the game row | In `SC@IRM`. ORIS documents player suspension on the line-up, not as a game-score mark |
| `startText` | Needed when `HideStartDate=Y` (`TBD` / `TBC`). Same platform gap as common |
| `HALF` missing | Cannot choose Top vs Bottom from `SC@Period` alone |

`liveCurrentProgress` itself exists on the platform API; BSB must fill `period.code` / `period.name` as in §3.3. `resultDecision` must stay empty until Forfeit has a field.

### Open product questions

1. **Forfeit:** Which ODF field should the backend read until the Data Dictionary grows a code (nothing matches `UI/RES_CODE` today)? Which score row shows **(Forfeit)** — the winning team, the losing team, or the unit? Should a group-stage DSQ that ORIS rewrites as 0–9 / 0–7 use the same indicator?
2. **Placeholder text:** For `TBD`, `WQF`, `A1`–`B3`, and `1A`–`4A`, is the tile string the OSRP word **TBD**, the CC description (often the code itself, or “1st in Group Stage”), or something else? Confirm `LSF` / `WSF` stay “Semifinal Loser” / “Semifinal Winner”.
3. **No Game:** What status, score, and label does the tile show when ORIS declares No Game?
4. **`SUS`:** Can `Result/@IRM=SUS` appear on a game tile, or is suspension only a player line-up state that the tile ignores?

---

## 7. BSB cheat sheet

```
BEFORE:  DT_SCHEDULE  →  meta, T teams | place-code placeholders (name: §6)
         order 1 visitor, 2 home
         no groupId; no Schedule=S units
DURING:  + DT_RESULT (± DT_CURRENT PERIOD only)
         →  runs, UI/PERIOD + HALF T|B → "Top n" | "Bottom n"
         do not map balls/strikes/outs
AFTER:   + DT_RESULT  →  runs, W/L, row IRM, medal icon on medal-game winner
         clear half-inning (PERIOD removed when official)
         Forfeit indicator: no ODF field yet — do not invent
```
