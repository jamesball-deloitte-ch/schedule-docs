# FBL Schedule Tile — Score / IRM / Winner / Live progress (FE summary)

**Audience:** Frontend implementing the results box on the schedule card  
**Full mapping:** [schedule-tile-fe.md](./schedule-tile-fe.md) · **Shared baseline:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**API:** [SCDLA Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule)

**Versions:** OSRP FBL LA28 R4 V1.0 · SC/CC OG2028 v1.6.0 · Confluence Schedule v24

Scope of this note: **score cell**, **IRM**, **winner**, `resultDecision`, **live period**, and how FBL differs from common. Everything else (time, status, placeholders, redirects) → common + full FE map.

---

## 1. FBL vs common (results box)

What FBL adds or tightens relative to the shared H2H card:

- **Teams only** — `competitors[].type = "T"`, names from `teamNames` (no athlete rows).
- **Live progress** — during the match show period from `liveCurrentProgress.period.code` only (e.g. `H1`, `HT`, `PSO`); ignore `.name` and `.time` for now.
- `resultDecision` — unit-level indicator after the match: `AET` · `PSO` · `FORFEIT` · `VOIDED` (inline with the score, per OSRP).
- `psoResult` — when PSO, show shoot-out tallies as `(n)` beside each side’s score.
- **Winner only after finish** — `winLoseTie === "W"` → chevron / bold solely when `scheduleStatus === "FINISHED"` (never during live).

IRM (`invalidResultMark`) and base score (`result.result`) follow common — no FBL twist beyond the patterns below.

---

## 2. Live progress

Show only while during (`RUNNING` / `INTERRUPTED` / `SCHEDULED_BREAK`) and `liveCurrentProgress` is present. Clear / hide when finished or before start.


| API                               | FE (current)                                                             |
| --------------------------------- | ------------------------------------------------------------------------ |
| `liveCurrentProgress.period.code` | **Display this** — `H1`, `HT`, `H2`, `ET-H1`, `ET-HT`, `ET-H2`, `PSO`, … |
| `liveCurrentProgress.period.name` | Ignore for now (full labels later if product asks)                       |
| `liveCurrentProgress.time`        | Never on tile                                                            |


Placement: beside status / under start time — **not** inside the score cell. One place only. Example layout → §4 (During — H1).

---

## 3. API → score row


| UI              | Field                                     | When                                                                          |
| --------------- | ----------------------------------------- | ----------------------------------------------------------------------------- |
| Score `n`       | `competitors[].result.result`             | During + after (not before)                                                   |
| PSO paren `(n)` | `competitors[].result.psoResult`          | When shoot-out tallies exist (typically with `resultDecision.code === "PSO"`) |
| Decision label  | `resultDecision.code` / `.name`           | After (AET / PSO / Forfeit / Voided)                                          |
| IRM             | `competitors[].result.invalidResultMark`  | When sent (e.g. `WDR`)                                                        |
| Winner          | `competitors[].result.winLoseTie === "W"` | **Only if** `scheduleStatus === "FINISHED"`                                   |


Before start: empty score cells (teams or placeholders only).

---

## 4. Patterns (OSRP)

### During — H1 (`liveCurrentProgress.period.code === "H1"`)

```
Team Name        n
            H1
Team Name        n
```

`H1` from `period.code` (status / progress area). Same pattern for `HT`, `H2`, `ET-H1`, … — swap the code. No `.name`, no clock, no winner while live.

### Regular

```
Team Name        n
Team Name        n
```

No `resultDecision`. Winner chevron only after finish.

### AET (`resultDecision.code === "AET"`)

```
Team Name               n
              AET
Team Name               n
```

Short **AET** or `resultDecision.name` (“After Extra Time”).

### PSO (`resultDecision.code === "PSO"`)

```
Team Name        n        (n)
                     PSO
Team Name        n        (n)
```

`result` = match goals; `psoResult` = paren tallies. Missing `psoResult` → still show **PSO**; do not invent `(n)`.

### Forfeit (`resultDecision.code === "FORFEIT"`)

```
Team Name                n
             Forfeit
Team Name                n
```

No separate abbr in OSRP/SC — use **Forfeit** (or description “Victory by Forfeit”). Code is `FORFEIT`, not `FF`.

### Voided (`resultDecision.code === "VOIDED"`)

Void indicator from `resultDecision`; scores if present.

### IRM

```
Team Name              n
Team Name     WDR      n
```

Per competitor. Do **not** map IRM into `resultDecision`. Example: WDR = Withdrawn

---

## 5. Winner rules

1. Read `winLoseTie === "W"`.
2. Apply chevron / bold **only when** `scheduleStatus === "FINISHED"`.
3. During live / break / interrupted: **no** winner marker even if `W` appears in API.

---

## 6. Checklist (this scope)

- [ ] Before: no scores  
- [ ] During: period from `liveCurrentProgress.period.code` only (no `.name`, no `.time`)  
- [ ] During / after: `result.result` in score cell  
- [ ] After: `resultDecision` inline (AET / PSO / Forfeit / Voided)  
- [ ] PSO: `(psoResult)` when provided  
- [ ] IRM from `invalidResultMark` on the row  
- [ ] Winner only after `FINISHED`  