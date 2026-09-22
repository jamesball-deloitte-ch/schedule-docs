# SQU — Schedule tile freeze (one playback)

**LogicalDate:** `2026-09-09` (same day as FBL / CLB / ARC freezes)  
**Folder:** [`01_Schedule_Tile_Mixed_Day`](01_Schedule_Tile_Mixed_Day) only  
**Ingest:** filename order (timestamp prefix).

Bodies from `rawData/SQU` (OG2028-ITL). Dates remapped to `2026-09-09`. Scores / IRMs / medallists unchanged.

Phases are CC `Schedule=N` — **no phase cards**.

---

## Playback (stop and look after step 2)

| Step | File prefix | Message | Now (approx) | What to check |
|------|-------------|---------|--------------|---------------|
| 1 | `080000000` | `DT_PARTIC_UPDATE` | 08:00 | athletes loaded |
| 2 | `080001000` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | **same 9 RSCs, all SCHEDULED, no `StartList`** → tiles = event/phase only, no opponents |
| 3 | `143000000` | `DT_SCHEDULE_UPDATE` **v2** | 14:30 | statuses + start lists (Women finished, Men mid/live) |
| 4 | `143001*` | `DT_RESULT` | 14:30 | scores, IRM/W/O, LIVE QF2 |
| 5 | `143010000` | `DT_MEDALLISTS` | 14:30 | Women’s gold + bronze |
| 6 | `143011000` | `DT_MEDALS` | 14:30 | standings: SUI gold, CZE bronze (no silver) |

Step 2 is the “before opponents” beat. Raw dump has no true pre-draw R16 (Event Config already has R16 names), so v1 uses the **same unit RSC set** as v2 with `StartList` omitted — then v2 overlays real schedule fragments from rawData.

---

## After full ingest (`now = 14:30`)

### Women’s Singles — medals done

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| Bronze | `SQUWSINGLES-----------FNL-000200--` | FINISHED | Sramkova vs `NOCOMP`, `medalFlag=3` (no `@Result` digits in dump) |
| Gold | `SQUWSINGLES-----------FNL-000100--` | FINISHED | Allinckx vs `NOCOMP`, `medalFlag=1` |
| Medallists | `DT_MEDALLISTS` | OFFICIAL | Gold Allinckx; Bronze Sramkova (no silver — SF2 was `2DSQ`) |

### Men’s Singles — mid + live

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| R16 | `…8FNL000100--` | FINISHED | **W/O** (`RES_CODE`) |
| R16 | `…8FNL000200--` | FINISHED | Zhou **RET** 0 vs Shcherbakov 3 |
| QF1 | `…QFNL000100--` | FINISHED | Omlor **3** – Shcherbakov **2** |
| QF2 | `…QFNL000200--` | **RUNNING** | Iqbal **0** – Byrtus **2**, `liveCurrentProgress` = **G3** |
| QF3 | `…QFNL000300--` | GETTING_READY | Rodriguez vs Farkas |
| SF1 | `…SFNL000100--` | SCHEDULED | Omlor vs **TBD** (PreviousUnit QF1 / UnitNum 09) |
| SF2 | `…SFNL000200--` | SCHEDULED | no StartList |

### Score ODF

`competitors[].result.result` ← `DT_RESULT/Result/@Result` (games won); live game ← `UI/PERIOD`; decisions ← `UI/RES_CODE`.

### Redirects

Every tile → unit-results of **that** RSC (no overrides).

**Acceptance criteria:** [AC.feature](AC.feature)

## Sources in rawData

| Piece | rawData |
|-------|---------|
| PARTIC | `01_Pre-Competiton` |
| Schedule v2 unit overlays | Day01 R16, Day05 QF, Day06 QF3, Day09 W finals, Event Config (empty SF2) |
| W RESULT + MEDALLISTS + MEDALS | `10_Day09 - 23 July WS Finals` |
| M QF1 OFFICIAL + QF2 LIVE | `06_Day05 - 19 July Quarterfinals` |
| M R16 W/O + RET | `02_Day01 - 15 July Round of 16` |
| Schedule v1 skeletons | Event Configuration unit shells (StartList cleared for playback) |
