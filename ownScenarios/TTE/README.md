# TTE — Medals for all events

**LogicalDate:** `2026-09-09` (same day as FBL / CLB / ARC freezes)  
**Now:** `2026-09-09T16:00:06+02:00` (all six events finished, standings closed)  
**Ingest:** filename order (timestamp prefix) under `01_Medals_All_Events`.

Bodies: athletes / teams / entries from `rawData/TTE` (OG2028-ITL). `DT_MEDALLISTS` and `DT_MEDALS` are fabricated from those participants (world-rank leaders as podiums).

## Events covered (6 / 6)

| Event | RSC | Gold | Silver | Bronze |
|-------|-----|------|--------|--------|
| Mixed Doubles | `TTEXDOUBLES` | CHN Wang / Sun | JPN Harimoto / Hayata | KOR Lim / Shin |
| Men's Doubles | `TTEMDOUBLES` | CHN Fan / Ma | GER Qiu / Ovtcharov | FRA Gauzy / Lebrun A. |
| Women's Doubles | `TTEWDOUBLES` | CHN Chen / Sun | JPN Hayata / Harimoto M. | KOR Shin / Jeon |
| Men's Singles | `TTEMSINGLES` | CHN Wang Chuqin | FRA Lebrun Felix | JPN Harimoto Tomokazu |
| Women's Singles | `TTEWSINGLES` | CHN Sun Yingsha | JPN Hayata Hina | KOR Shin Yubin |
| Mixed Team | `TTEXTEAM` | CHN | JPN | KOR |

Gold / bronze units: singles & doubles `FNL-000100--` / `FNL-000200--`; Mixed Team `FNL-00010000` / `FNL-00020000`.

## Medal table (`DT_MEDALS`)

| Rank | NOC | G | S | B | Total |
|------|-----|---|---|---|-------|
| 1 | CHN | 6 | 0 | 0 | 6 |
| 2 | JPN | 0 | 4 | 1 | 5 |
| 3 | FRA | 0 | 1 | 1 | 2 |
| 4 | GER | 0 | 1 | 0 | 1 |
| 5 | KOR | 0 | 0 | 4 | 4 |

`LastEvent` = `TTEXTEAM--------------------------`, `FinishedEvents=6` / `TotalEvents=6`. Summary types: `TOT`, `M`, `W`, `X`.

## Playback

1. `DT_PARTIC_UPDATE` — 23 athletes used on the podiums (+ team compositions).  
2. `DT_PARTIC_TEAMS_UPDATE` — 12 team identities (doubles + mixed team).  
3. `DT_ENTRIES` for all six events (full lists from rawData).  
4. Six `DT_MEDALLISTS` (one per event), then one discipline `DT_MEDALS`.

**Acceptance criteria:** [AC.feature](AC.feature)

## Sources in rawData

| Freeze piece | rawData |
|--------------|---------|
| PARTIC | `TTE_DT_PARTIC_20260625_163820121.xml` |
| TEAMS | `TTE_DT_PARTIC_TEAMS_20260626_120221221.xml` |
| ENTRIES | `TTE_TTEMSINGLES`, `TTE_TTEWSINGLES`, `TTEMDOUBLES`, `TTEWDOUBLES`, `TTEXDOUBLES`, `TTEXTEAM` |
| Medallists / standings | Fabricated (`DT_MEDALLISTS` / `DT_MEDALS`) |
