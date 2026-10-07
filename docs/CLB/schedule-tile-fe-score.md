# CLB Schedule Tile — Results box (FE summary)

**Audience:** Frontend schedule card (WMR / CIS)  
**Pack:** [schedule-tile-requirements.md](./schedule-tile-requirements.md) · [common](../common/schedule-tile-common.md)  
**API:** [SCDLA Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule)

**Versions:** OSRP CLB LA28 R4 V1.0 · flavour **event / phase row + medallists** (no climbing score on schedule tile)

---

## 1. CLB vs common (results box)

- **No climbing scores on the tile** — before and during: no score cell (boulder/lead/speed points stay on the results page).
- **No** `resultDecision`, **no** `liveCurrentProgress` for the schedule card.
- **During:** live highlight via `liveFlag` / `scheduleStatus` only.
- **After:** show **all medallists** — NOC + athlete + medal — from `competitors[]` with `result.medal` (usual three; ties → more rows).
- **`placeholderOpponents` / H2H rows: not on the schedule tile.** Per `CC@Phase` / `CC@Unit` (OG2028): Speed bracket stages are **phase `Schedule=Y`** (e.g. Men's Speed Finals); pair races are **unit `Schedule=S`** and are not listed as separate cards — so no per-pair TBD/opponent UI on Daily Schedule.
- **RSC overrides:** Speed phases are on [Schedule RSC overrides](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3229941783/Schedule+RSC+overrides) — one shared results screen per bracket stage (e.g. `CLBMSPEED-------------FNL---------` → `CLBMSPEED-------------FNL-000100--`). Card click must prefer `overrideRsc` when set.

---

## 2. Phase → results area

| Phase | FE |
|-------|-----|
| Before | Empty results area (event / phase chrome only) |
| During | Empty results area + live status highlight |
| After | All medallist rows (`result.medal`; >3 if ties) |

Same shape as CRD for the results box. No “one known / one TBD” competitor pair on this surface.

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

Do not invent medallists. Do not render climbing totals / IRMs as a schedule scoreboard.

---

## 3. Checklist

- [ ] Before / during: no score block  
- [ ] During: live highlight only  
- [ ] After: all medallist rows from API medals (incl. ties)  
- [ ] No H2H / `placeholderOpponents` UI on schedule tile (Speed pair units = CC `S`; phase = `Y`)  
- [ ] Card click: use `overrideRsc` for Speed phases (shared finals/brackets screen)  
- [ ] No `resultDecision` / period progress on CLB schedule card  
