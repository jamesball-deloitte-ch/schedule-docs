# ARC Schedule Tile — Score / IRM / Winner (FE summary)

**Audience:** Frontend implementing the results box on the schedule card  
**Pack:** [schedule-tile-requirements.md](./schedule-tile-requirements.md) · [common](../common/schedule-tile-common.md)  
**API:** [SCDLA Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule)

**Versions:** OSRP ARC LA28 R4 V1.0 · flavour **H2H + score** (unlike CRD/CLB)

> ARC **does** show score on the schedule card (set points). It is not an event-row / medallists-only tile.

---

## 1. ARC vs common (results box)

- **Individuals and teams** — `type = "A"` (`athleteNames`) or `"T"` (`teamNames`).
- **Score** — `competitors[].result.result` during + after (set points / points).
- **No `resultDecision`** — no AET / PSO / Forfeit on ARC schedule samples.
- **IRM** — `invalidResultMark` on the row (`DNS`, `DNF`, `DSQ`, `DQB`).
- **Winner** — `winLoseTie === "W"` after the match (`FINISHED`).
- **Live progress (optional)** — current set / shoot-off via `liveCurrentProgress` if BE sends it (`Set n` / `SO`); secondary to score. Prefer **code** if product mirrors FBL “code only for now”.
- **`placeholderOpponents`:** **yes** — mainly `TBD` composed by BE as `Winner {n}` / `Runner-up {n}` (from `PreviousUnit` / `PreviousWLT`). Also `NOCOMP`. **BYE** / `UNSCHEDULED` units are **not listed**.
- Bye / `UNSCHEDULED` units: **not listed** (no card).

---

## 2. Competitors / placeholders

| Case | API | FE |
|------|-----|-----|
| Both known | `competitors[]` (`A` and/or `T`) | Flag + name; scores when during/after |
| Both TBD | `placeholderOpponents[]` | `name` as-is; **no scores** |
| **One known, one TBD** | One `competitors[]` + one `placeholderOpponents[]` (by `order`) | Known: flag + name (+ score if live/finished). Placeholder: text only, **empty score** |

```
SADIKOV Amirkhon (UZB)          —
Winner 70                       —
```

When the TBD side resolves, BE moves them into `competitors[]` and clears that `placeholderOpponents` entry — FE just re-renders.

Do not invent “Winner n” on the client.

---

## 3. API → score row

| UI | Field | When |
|----|-------|------|
| Score `n` | `competitors[].result.result` | During + after (**known** competitors only) |
| IRM | `competitors[].result.invalidResultMark` | When sent |
| Winner | `competitors[].result.winLoseTie === "W"` | After `FINISHED` |
| Medal on row | `competitors[].result.medal` / unit `medalFlag` | Medal matches |

Before: names or placeholders; **no scores**. Placeholder rows never show a numeric score.

---

## 4. Patterns (OSRP)

### Before — one known, one placeholder

```
Print Name / Team Name
Winner 70
```

(No scores.)

### Regular (both known, during/after)

```
Print Name / Team Name     n
Print Name / Team Name     n
```

### IRM

```
Print Name / Team Name              n
Print Name / Team Name    IRM       n
```

### Winner

Chevron / bold when `FINISHED` and `winLoseTie === "W"` (known competitors only).

---

## 5. Checklist

- [ ] Before: no scores  
- [ ] Support mixed `competitors[]` + `placeholderOpponents[]` by `order`  
- [ ] Placeholder `name` as-is; no client “Winner n” dictionary  
- [ ] During / after: score from `result.result` on known sides only  
- [ ] After: winner when `FINISHED`  
- [ ] IRM on row when present  
- [ ] No `resultDecision` / PSO paren on ARC  
- [ ] Optional set progress only if API provides `liveCurrentProgress`  
