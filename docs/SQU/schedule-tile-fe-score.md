# SQU Schedule Tile — Score / IRM / Winner (FE summary)

**Audience:** Frontend implementing the results box on the schedule card  
**Pack:** [schedule-tile-requirements.md](./schedule-tile-requirements.md) · **Shared baseline:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**API:** [SCDLA Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule)  
**Freeze:** [ownScenarios/SQU](../../ownScenarios/SQU/README.md)

**Versions:** OSRP SQU LA28 R4 V1.0 · SC/CC OG2028 v1.6.0 · Confluence Schedule

Scope: **games-won score**, **IRM**, **winner**, and **one-side placeholders** on the H2H row. Time, status chrome, redirects → common + pack.

**Not on the SQU schedule card** (do not copy FBL): `resultDecision`, `liveCurrentProgress` (no `G1`…`G5` chrome). OSRP §1.4 is live highlight + score; current game lives on Start List / Results, not the tile.

Squash schedule cards are **head-to-head + score** (individuals). They are not event-row / medallists-only tiles.

---

## 1. What the results box shows

- **Athletes** — `competitors[].type = "A"`; print name + NOC/flag from `athleteNames` / organisation.
- **Score** — match **games won** in `competitors[].result.result` (integer), during and after.
- **IRM** — `competitors[].result.invalidResultMark` on that athlete’s row (`RET`, `W/O`, `DSQ`, `DQB`, …). If both sides have an IRM, show it on **both** rows.
- **Winner** — `winLoseTie === "W"` only after `scheduleStatus === "FINISHED"`.
- **Medal** — medal symbol on the winner of a medal match (`medalFlag` / `competitors[].result.medal`).
- **Placeholder (mixed only)** — one `placeholderOpponents[]` row when **one** opponent is known and the other is not. Print `name` as-is (almost always `TBD`). **No score** on that row. Do not invent `Winner n`.

---

## 2. Competitors / placeholders

| Case | API | FE |
|------|-----|-----|
| Both known | `competitors[]` | Flag + print name; scores when during/after |
| One known, one unknown | One `competitors[]` + one `placeholderOpponents[]` (by `order`) | Known: name (+ score if live/finished). Placeholder: `name` as sent (`TBD`), empty score cell |
| Both unknown | Empty `competitors[]` **and** empty `placeholderOpponents[]` | Event/phase meta only — **no** H2H rows, **no** `Winner n` / dual `TBD` |
| Place code (`NOCOMP`, …) | Often as competitor `code` / place | Follow product copy; still **no invented score** |

```
OMLOR Yannik (GER)          —
TBD                         —
```

FE must **not** map `PreviousUnit` / bracket position into display names. If BE sends `TBD`, show `TBD`.

Before the draw (no start list): empty `competitors` / placeholders — show event/phase meta only.

---

## 3. API → score row

| UI | Field | When |
|----|-------|------|
| Score `n` | `competitors[].result.result` | During + after (**known** athletes only) |
| IRM | `competitors[].result.invalidResultMark` | When sent |
| Winner | `competitors[].result.winLoseTie === "W"` | **Only if** `scheduleStatus === "FINISHED"` |
| Medal on row | `competitors[].result.medal` / unit `medalFlag` | Medal matches |

Before start: names or mixed placeholder only — **empty score cells**.

During: live highlight + games-won score. **No** current-game code.

---

## 4. Patterns (OSRP)

### During

```
Print Name        n
Print Name        n
```

Live highlight / In Progress. No winner marker while live. No `G1`…`G5` on the card.

### Regular (finished, no IRM)

```
Print Name        n
Print Name        n
```

Winner chevron / bold on the side with `winLoseTie === "W"` after `FINISHED`.

### IRM (per athlete)

```
Print Name              n
Print Name     RET      n
```

`invalidResultMark` on that row (`RET`, `W/O`, `DSQ`, `DQB`, …). Keep the games-won digit when BE still sends `result`. Same pattern if both rows have an IRM.

Walkover / retirement is the IRM on the row (`W/O`, `RET`).

### Mixed placeholder (one known)

```
Print Name              —
TBD                     —
```

No score on the placeholder row. No winner marker on that row.

### Both unknown

No results-box rows — phase/event only (same idea as before-draw / later phases before opponents exist).

### Medal match (after)

Same score / IRM patterns; add medal symbol on the winning athlete when `FINISHED`.

---

## 5. Winner rules

1. Read `competitors[].result.winLoseTie === "W"`.
2. Apply chevron / bold **only when** `scheduleStatus === "FINISHED"`.
3. During live / break / interrupted: **no** winner marker.
4. Never mark a placeholder row as winner.

---

## 6. Checklist (this scope)

- [ ] Before: no scores; empty rows unless mixed placeholder  
- [ ] Placeholder **only** when one competitor is known  
- [ ] Placeholder `name` as-is (`TBD`); no client `Winner n` dictionary  
- [ ] During / after: games won from `result.result` on known sides  
- [ ] During: live highlight + score; **no** `liveCurrentProgress`  
- [ ] IRM from `invalidResultMark` on the row  
- [ ] No `resultDecision` chrome  
- [ ] Winner only after `FINISHED`  
- [ ] Medal symbol on medal-match winner  
