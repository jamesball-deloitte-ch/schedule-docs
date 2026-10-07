# TRI — Schedule tile results box (FE)

**Versions:** OSRP TRI LA28 R4 V1.0 · flavour **event row + medallists** (no race score on schedule tile)  
**Pack:** [schedule-tile-requirements.md](./schedule-tile-requirements.md)  
**Freeze:** [ownScenarios/TRI](../../ownScenarios/TRI) · ticket [DRES-32642](https://dgplatform.atlassian.net/browse/DRES-32642)

TRI is **not** H2H. The card never shows swim/bike/run times or ranks as a schedule “scoreboard”.

---

## Phase → what the card shows

| Phase | Card chrome | Results / competitor block |
|-------|-------------|----------------------------|
| **Before** | Event, time, venue, medal flag, status (not “Scheduled”) | **Empty** — no start list, no names, no IRM |
| **During** | Same + **live** highlight (`liveFlag`) | **Empty** — live = status only, no live times |
| **After** | Finished / result status | **Medallists only** (default, no country filter) |

### After — medallists (no country filter)

| Event | Row content |
|-------|-------------|
| Women’s / Men’s Individual | Flag + NOC + **athlete** name + medal icon |
| Mixed Relay | Flag + NOC + **team** name + medal icon |

Show **all** rows with `result.medal` (ties may be >3). Do not render the full start list.

---

## Country / NOC filter

API keeps the **full** `competitors[]` always ([common §3.3.1](../common/schedule-tile-common.md)).

| Surface | Behaviour |
|---------|-----------|
| Filter off | Card as in the phase table above |
| Filter on (NOC = X) | Tile stays listed if any `competitors[].organisation == X`. Results block shows **only** matching competitors: athletes (`type=A`) for individual finals; **teams** (`type=T`) for Mixed Relay |

### IRM (country filter only)

| Condition | Show IRM on row? |
|-----------|------------------|
| No country filter | **No** — even if `result.IRM` is set (DNF/DNS/LAP/…) |
| Country filter on **and** competitor `organisation` = filtered NOC | **Yes** — IRM badge/code on that athlete or team row |
| Country filter on **and** competitor from another NOC | Row not shown |

IRM codes in freeze examples: Men `DNF`/`LAP`, Women `DNF`/`DNS`/`LAP`, Mixed `DNF`/`LAP`/`DSQ`/`DQB`.

---

## Checklist

- [ ] Before: no competitor / medallist / IRM block  
- [ ] During: live highlight only; no result values  
- [ ] After (no filter): athlete medallists (individual) / team medallists (relay)  
- [ ] Country filter: show matching athletes or teams; IRM only on those rows  
- [ ] No race score / segment progress on the schedule card  
