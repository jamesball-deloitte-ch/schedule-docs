# CKT Schedule Tile — Developer Requirements

**Scope:** Cricket (CKT) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**FE component extension (baseline Figma → CKT slots):** [schedule-tile-fe-component.md](./schedule-tile-fe-component.md)  
**Editions:** OSRP LA28 R4 V1.0 · ORIS LA28 R9 V1.1 · ODF `OG2028-CKT-0.3` · SC/CC `OG2028` v1.5.0  
**RawData:** `rawData/CKT` (sim / SignalR captures with `DT_SCHEDULE_UPDATE`, `DT_RESULT`, …)  
**API:** [Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule) — includes CKT-specific `extendedResultInfo.finalResultDescription`.

---

## 1. CKT vs common

| Topic | CKT behaviour |
|-------|----------------|
| Competitors | Teams (`Type=T`) |
| Live progress | Current **innings** (+ over) → `liveCurrentProgress` (§3.2) |
| Score | Runs/wickets `nnn/n` (+ overs); **Yet to bat** (`YTB`) for side not batting |
| After text | Interpolated sentence from `UI/FINAL_RESULT` → `extendedResultInfo.finalResultDescription` (§3.3) |
| `resultDecision` | **Not primary** — use FINAL_RESULT / ResultDesc instead of FBL-style RES_CODE |
| Placeholders | `TBD`, `ROUND2_R1`…`R4`, `NOCOMP` (`SC@CompetitorPlace`) |
| Group label | Group stage: event name like “Women's Group A” |
| Grouping | N/A (OSRP) |
| Interrupt outcomes | May finish as **No Result** / **Abandoned** (ORIS) |

---

## 2. Situations (OSRP §1.2 + ORIS §3.1.6)

### 2.1 Before

- Date, start time, discipline / event / phase, match number.
- Group stage: show “Event name Group x”.
- Opponents confirmed: NOC + team name.
- Not confirmed: **`TBD`** or **Stage 2 Rank n** (codes → SC Description, §3.5).
- No “Scheduled” badge; medal marker when applicable.

### 2.2 During

- Live highlight.
- Batting side: live score `nnn/n` (overs as `(n.n)` / `(nn)` per OSRP format).
- Side not yet batted: text **Yet to bat** (ODF `YTB` / `SC@ResultMark`).
- First innings only: Match info line **“First innings: {Team} elected to bat/field”** from `ER/TOSS` (§3.4) — not from `UI/BATTING`.
- Optional progress: current innings (and over) via `liveCurrentProgress`.

### 2.3 After

- Winner indicated (`WLT`).
- Scores for both sides (incl. Super Over line when played).
- **Match situation** sentence, e.g.  
  `India beat Pakistan by 9 wickets` / `… by 44 runs` / `… in Super Over` / `Match Abandoned` / `No Result`.
- Medal symbol on medal matches.

### 2.4 Score formats (OSRP)

Regular:

```
Team Name        nnn/n (n.n or nn)
Team Name        nnn/n (n.n or nn)
Match situation text
```

Super Over:

```
Team Name        nnn/n (…) SO n/n (…)
Team Name        nnn/n (…) SO n/n (…)
Match situation text
```

### 2.5 Exceptional (ORIS)

Same schedule statuses as common (Cricket IF may use different words; **OC codes** apply). Extra:

| Situation | Tile / data impact |
|-----------|-------------------|
| Interrupted → cannot complete | Often **No Result** (not only postpone) |
| Abandoned (no play) | Result **Match Abandoned**; group points rules per ORIS |
| DLS revised target / win | Situation text may include DLS (OSRP); feed via ResultDesc / extensions when provided |
| Refuse to play | Default win sentence (`BYDEFAULT`) |
| DQB | Team/player IRM path |

---

## 3. Backend — CKT

Implements [common §3](../common/schedule-tile-common.md) plus below.

### 3.1 ODF messages

| Message | CKT tile role |
|---------|----------------|
| `DT_SCHEDULE[_UPDATE]` | Meta, status, teams / place codes |
| `DT_RESULT` | LIVE scores, `YTB`, `UI/PERIOD` (+ OVER), `ER/TOSS`, `UI/BATTING`, `UI/FINAL_RESULT`, WLT |
| `DT_CURRENT` | If present — live merge (prefer with RESULT) |
| `DT_PARTIC_TEAMS` | Team names for `#ORG*` interpolation |

### 3.2 `liveCurrentProgress` (innings / over)

```
DT_RESULT  ExtendedInfo[@Type='UI'][@Code='PERIOD']/@Value     e.g. IN1, IN2, SO1IN1
           Extension[@Code='OVER']/@Value                      e.g. O11  (optional)
        │
        ▼
SC@Period Description   "1st Innings" / "2nd Innings" / "Over 11" / "Super Over" …
        │
        ▼
liveCurrentProgress.code = PERIOD value (e.g. "IN2")
liveCurrentProgress.name = SC Description (e.g. "2nd Innings")
# optional: expose over as name suffix or separate field if product needs "(O11)"
```

| When | API |
|------|-----|
| Match live / intermediate | Set from latest PERIOD (keep previous innings code during scheduled break — ODF) |
| Finished / before start | `null` |

RawData example: `PERIOD Value="IN2"` + `Extension Code="OVER" Value="O11"`.

### 3.3 `extendedResultInfo.finalResultDescription` (Confluence — CKT)

Confluence: shared ExtendedInfo `Code=FINAL_RESULT`; **replace variables** in the CC/SC string with team names and score.

```
DT_RESULT  ExtendedInfo[@Type='UI'][@Code='FINAL_RESULT']/@Value     e.g. WON_WKT
           Extension PH_TEAM Pos=1 → winner team id
           Extension PH_TEAM Pos=2 → loser team id
           Extension SCORE → margin (runs/wickets) when applicable
        │
        ▼
SC@ResultDesc Description template
  e.g. "#ORG1 beat #ORG2 by #SCR wickets"
        │
        ▼
Replace:
  #ORG1 ← team name (or NOC) for PH_TEAM Pos=1
  #ORG2 ← team name for Pos=2
  #SCR  ← Extension SCORE
        │
        ▼
API  extendedResultInfo.finalResultDescription
     = "India beat Pakistan by 9 wickets"
```

#### `SC@ResultDesc` (CKT) — templates

| Code | Template (Description) |
|------|------------------------|
| `WON_WKT` | `#ORG1 beat #ORG2 by #SCR wickets` |
| `WON_RUN` | `#ORG1 beat #ORG2 by #SCR runs` |
| `WON_SO` | `Match tied, #ORG1 beat #ORG2 in Super Over` |
| `WON_SO2`…`WON_SO5` | `… in second/third/… Super Over` |
| `TIED` | `Match tied` |
| `ABANDONED` | `#ORG1 vs #ORG2 - Match Abandoned` |
| `NO_RESULT` | `#ORG1 vs #ORG2 - No Result` |
| `BYDEFAULT` | `#ORG1 beat #ORG2 (by default)` |

#### Worked example (rawData)

`FINAL_RESULT Value="WON_WKT"`  
`PH_TEAM Pos=1` = India team, `Pos=2` = Pakistan, `SCORE=9`  
→ **`India beat Pakistan by 9 wickets`**.

`WON_RUN` + `SCORE=44` → **`Australia beat New Zealand by 44 runs`**.  
`WON_SO2` (no SCORE in sample) → use template without `#SCR`.

Populate from **UNOFFICIAL** onward (ODF); clear or omit before match end.

### 3.4 During extras — Yet to bat / toss (elected line)

| UI | ODF |
|----|-----|
| Score `128/5` | `Result/@Result` (`ResultType=SCORE`) and/or `Periods/Period` scores |
| **Yet to bat** | `Result` with `IRM`/`ResultMark` **YTB**, or period `HomeScore`/`AwayScore` = `YTB` |
| **Elected to bat/field** | `Result/ExtendedResults/ExtendedResult[@Type='ER'][@Code='TOSS']` — see below |

FE may show `YTB` as the OSRP phrase **Yet to bat** (SC Description).

#### First-innings Match info — “elected to bat/field”

Product copy (OSRP / summary):  
`First innings: {Toss winning team name} elected to {bat|field}`

This is **composed by BE** (not a single ODF string). Do **not** use `UI/BATTING` for the team name — that code is the side currently batting, which can differ from the toss winner (e.g. toss winner elects to field).

```
DT_RESULT  Result[…]/ExtendedResults/ExtendedResult[@Type='ER'][@Code='TOSS']
           — Element expected: after the toss, only on the Result of the team that won the toss
           @Value = SC@Toss Code   (BAT | FIELD)
        │
        ▼
Team name  ← Competitor on that same Result (DT_PARTIC_TEAMS / Description)
Verb       ← SC@Toss: BAT → "bat", FIELD → "field"
Gate       ← UI/PERIOD @Value == IN1   (first innings only; hide once PERIOD moves to IN2 / SO*)
        │
        ▼
API        match-info / elected line (or agreed field)
           = "First innings: India elected to bat"
```

| Part | Source | Notes |
|------|--------|--------|
| Toss-winning team | Parent `Result/Competitor` of `ER/TOSS` | ODF sends `TOSS` only for the winner of the toss |
| `bat` / `field` | `ExtendedResult[@Code='TOSS']/@Value` → **SC@Toss** | `BAT` = “Won the toss and elected to bat”; `FIELD` = “… elected to field” |
| Show only in 1st innings | `ExtendedInfo[@Type='UI'][@Code='PERIOD']/@Value` = `IN1` | Clear / omit when `PERIOD` ≠ `IN1` (or when match finished → use §3.3 instead) |

#### `SC@Toss` (CKT)

| Code | Description |
|------|-------------|
| `BAT` | Won the toss and elected to bat |
| `FIELD` | Won the toss and elected to field |

**Invalid:** free text (`"BOWL"`, `"bat"`, …). Only `BAT` / `FIELD`.

#### Worked example

```xml
<Result …>
  <Competitor Code="CKTMT20---------------IND01" Type="T" Organisation="IND">…</Competitor>
  <ExtendedResults>
    <ExtendedResult Type="ER" Code="TOSS" Value="BAT"/>
  </ExtendedResults>
</Result>
<!-- UI/PERIOD Value="IN1" -->
```

→ **`First innings: India elected to bat`**.

`TOSS Value="FIELD"` + same gate → **`First innings: India elected to field`**.

### 3.5 Placeholder opponents

`SC@CompetitorPlace` (CKT):

| Code | Description → `placeholderOpponents[].name` |
|------|-----------------------------------------------|
| `TBD` | To be determined |
| `ROUND2_R1`…`ROUND2_R4` | Second Round Rank 1…4 (OSRP “Stage 2 Rank n”) |
| `NOCOMP` | No competitor |

Prefer **Description as `name`** (same pattern as FBL). RawData schedule dump in this repo had little TBD; codes are authoritative for medal / stage-2 tiles.

### 3.6 `resultDecision` / RES_CODE

Not required for CKT schedule tile UX. Match outcome sentence is **`finalResultDescription`**. Do not conflate with FBL AET/PSO.

### 3.7 `startText`

Follow [common §3.4](../common/schedule-tile-common.md) when `HideStartDate=Y`.

### 3.8 CKT backend checklist

Shared plus:

- [ ] Scores as runs/wickets; map `YTB` → Yet to bat  
- [ ] `liveCurrentProgress` from `UI/PERIOD` (+ optional OVER)  
- [ ] First-innings elected line from `ER/TOSS` + Competitor + `PERIOD=IN1` (§3.4)  
- [ ] `finalResultDescription` interpolated from `SC@ResultDesc` + PH_TEAM + SCORE  
- [ ] Placeholders `TBD` / `ROUND2_R*` via CompetitorPlace Description  
- [ ] Super Over scores available when PERIOD/SO* present  
- [ ] Abandoned / No Result / default templates supported  

---

## 4. Frontend — CKT

Shared layout plus (detail: [schedule-tile-fe-component.md](./schedule-tile-fe-component.md)):

| Phase | FE |
|-------|-----|
| Before | Placeholders as BE `name` (`TBD`, `Second Round Rank n`) |
| During | Live score; **Yet to bat** for non-batting side; optional innings progress; first-innings elected line from BE (§3.4) |
| After | Both scores (+ SO line); winner; **`finalResultDescription`** as match-situation line; medal icon |

Do not invent the situation sentence on FE — render `extendedResultInfo.finalResultDescription` from BE.

Baseline Figma already has a hidden **Match info** strip — enable it for CKT situation / elected copy; extend the **score cell** beyond a plain integer.

### 4.1 Card click redirects

Same phase rule as [common §4.3](../common/schedule-tile-common.md) — **href does not change** for before / during / after. **WMR path shape differs** from `/results/unit/{rsc}` (compact LA28 tree).

| Surface | On card click → |
|---------|-----------------|
| **CIS** (pool example `CKTMTEAM--------------GPA-000100--`) | `/en/OG2028/CKT/M/TEAM--------------/GPA-/000100--/results` |
| **WMR** (group example `CKTMT20---------------GP1A000100--`) | `/en/los-angeles-2028/results/ckt/mck/gp1a/000100--` |
| **WMR** (women / GP1B `CKTWT20---------------GP1B000200--`) | `/en/los-angeles-2028/results/ckt/wck/gp1b/000200--` |

WMR builder: `resolveCktGroupStandingsMatchHref` — maps gender → `mck`/`wck`, phase → `gp1a`/`gp1b`/`gp2`/`semifinal`/`final`, unit tail → `000100--`. Unknown phase → no link.

---

## 5. API gaps (CKT view)

| Field | Status |
|-------|--------|
| `extendedResultInfo.finalResultDescription` | **On Confluence** — implement §3.3 |
| `liveCurrentProgress` | On Confluence — use for innings (§3.2), not only FBL |
| `startText` | Still missing if HideStartDate used |
| `resultDecision` | Not needed for CKT |
| Toss / “elected to bat” line | Compose on BE from `ER/TOSS` (§3.4); expose via Match info API field (confirm name with Schedule API) — **not** FE-parsed from raw ODF |

---

## 6. CKT cheat sheet

```
BEFORE:  DT_SCHEDULE  →  teams | TBD / ROUND2_Rn → placeholders
DURING:  DT_RESULT    →  SCORE | YTB, PERIOD(+OVER) → liveCurrentProgress
           ER/TOSS (+ PERIOD=IN1) → elected Match info line
AFTER:   DT_RESULT    →  scores, WLT, FINAL_RESULT + SC@ResultDesc → finalResultDescription
```
