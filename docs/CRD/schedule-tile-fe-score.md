# CRD Schedule Tile — Results box (FE summary)

**Audience:** Frontend schedule card (WMR / CIS)  
**Pack:** [schedule-tile-requirements.md](./schedule-tile-requirements.md) · [common](../common/schedule-tile-common.md)  
**API:** [SCDLA Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule)

**Versions:** OSRP CRD LA28 R4 V1.0 · flavour **event row + medallists** (no H2H score)

---

## 1. CRD vs common (results box)

- **No score on the tile** — before and during: no `result.result` / H2H score cell.
- **No** `resultDecision`, **no** `psoResult`, **no** FBL-style `liveCurrentProgress` on the schedule card.
- **During:** live highlight via `liveFlag` / `scheduleStatus` only.
- **After:** show **all medallists** — NOC + athlete name + medal — from `competitors[]` rows that have `result.medal` (`GOLD` / `SILVER` / `BRONZE`); ties → more than three rows. Not match scores.
- **Full start list:** API **must** return **all** start-list athletes in `competitors[]` (global NOC filter). **Do not** render the peloton on the schedule card — only medallist rows after finish.
- **`placeholderOpponents`:** effectively **N/A** on the CRD schedule tile (not an H2H card). `SC@CompetitorPlace` is minimal (`NOAWARD` only) — no “one known / one TBD opponent” row pair.

---

## 2. Phase → results area

| Phase | FE |
|-------|-----|
| Before | Empty results area (event/phase chrome only); ignore full `competitors[]` for display |
| During | Empty results area + live status highlight |
| After | All medallist rows (`result.medal` set; >3 if ties) |

There is **no** competitor H2H / full start-list block on the card. Country filter uses `competitors[].organisation` off-card.

### After — medallists

```
🏳️ Athlete Name     🥇
🏳️ Athlete Name     🥈
🏳️ Athlete Name     🥉
```

| API | UI |
|-----|-----|
| `competitors[].organisation` | Flag / NOC |
| `competitors[].athleteNames.*` | Name (`type = "A"`) |
| `competitors[].result.medal` | Medal icon |

Do not invent medallists if API has none. Do not show race ranks / IRMs as a scoreboard on this tile.

---

## 3. Checklist

- [ ] Before / during: no score block  
- [ ] During: live highlight only  
- [ ] After: all medallist rows from API medals (incl. ties)  
- [ ] No `resultDecision` / PSO / period progress on CRD schedule card  
- [ ] No H2H placeholder / mixed-opponent handling on this tile  
