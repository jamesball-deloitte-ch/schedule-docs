# FBL — Schedule tile freeze (mid-group)

**LogicalDate:** `2026-09-09` (same day as CLB `01_Schedule_Tile_Mixed_Day` and ARC `01_Schedule_Tile_Mixed_Day`)  
**Now:** `2026-09-09T13:00:00+02:00` (Men’s Group A + B live; Group C interrupted at HT)  
**Ingest:** filename order (timestamp prefix) under `01_Schedule_Tile_Mid_Group`.

Bodies from `rawData/FBL` (Paris), dates remapped so group match-day 3 lands on `schedulesPerDay/2026-09-09`. Earlier group days and later knockouts stay in the same `DT_SCHEDULE_UPDATE` for other `schedulesPerDay/{date}` checks.

## What 2026-09-09 should show

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| Men's Group C | `FBLMTEAM11------------GPC-000300--` | INTERRUPTED | MLI 0–0 EGY. Period HT. Clock not running. |
| Men's Group B | `FBLMTEAM11------------GPB-000300--` | RUNNING | ARG 2–1 IRQ. `liveCurrentProgress` H2. |
| Men's Group A | `FBLMTEAM11------------GPA-000300--` | RUNNING | FRA 1–0 GUI. `liveCurrentProgress` H1. |
| Men's Group A | `FBLMTEAM11------------GPA-000400--` | SCHEDULED (no badge) | NZL vs JAM. `HideStartDate` + `startText=TBC`. |
| Men's Group C | `FBLMTEAM11------------GPC-000400--` | SCHEDULED (no badge) | DOM vs ESP. Clock 18:00. |
| Men's Group B | `FBLMTEAM11------------GPB-000400--` | SCHEDULED (no badge) | JPN vs MAR. |

Finished group matches (regular / AET / PSO / Forfeit) are on 2026-09-05…08. Women's QF `TBD` vs `TBD` is on 2026-09-14.

**Acceptance criteria:** [AC.feature](AC.feature)
