# SQU — Schedule tile freeze 01 (mixed / edge day)

**LogicalDate:** `2026-09-09` (same day as FBL / CLB / ARC freezes)  
**Folder:** [`01_Schedule_Tile_Mixed_Day`](.) only  
**Ingest:** filename order (timestamp prefix).

Bodies from `rawData/SQU` (OG2028-ITL). Dates remapped to `2026-09-09`. Scores / IRMs / medallists unchanged.

Phases are CC `Schedule=N` — **no phase cards**.

See also optimistic freeze: [`../02_Schedule_Tile_Women_Finals_Men_QF`](../02_Schedule_Tile_Women_Finals_Men_QF).

---

## Playback (stop and look after step 2)

| Step | File prefix | Message | Now (approx) | What to check |
|------|-------------|---------|--------------|---------------|
| 1 | `080000000` | `DT_PARTIC_UPDATE` | 08:00 | athletes loaded |
| 2 | `080001000` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | **same 10 RSCs, all SCHEDULED, no `StartList`** → tiles = event/phase only, no opponents |
| 3 | `143000000` | `DT_SCHEDULE_UPDATE` **v2** | 14:30 | statuses + start lists (Women finished, Men mid/live) |
| 4 | `143001*` | `DT_RESULT` | 14:30 | scores, IRM/W/O, LIVE QF2 (games won + liveFlag) |
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
| QF2 | `…QFNL000200--` | **RUNNING** | Iqbal **0** – Byrtus **2** (`liveFlag`; no current-game chrome) |
| QF3 | `…QFNL000300--` | GETTING_READY | Rodriguez vs Farkas |
| QF4 | `…QFNL000400--` | SCHEDULED | Zaman vs Zhu (no score; R16 `8FNL000700` / `8FNL000800` W) |
| SF1 | `…SFNL000100--` | SCHEDULED | Omlor vs **TBD** (mixed placeholder; do not compose Winner 10) |
| SF2 | `…SFNL000200--` | SCHEDULED | Both unknown → **no** H2H rows (phase/event only; ODF StartList may still be dual `TBD`) |

### Score ODF

`competitors[].result.result` ← `DT_RESULT/Result/@Result` (games won). Tile does not map `UI/PERIOD` or `UI/RES_CODE`.

### Redirects

Every tile → unit-results of **that** RSC (no overrides).

**Acceptance criteria:** [../AC.feature](../AC.feature)

---

## Fabricated / patched

| Piece | Note |
|-------|------|
| Men’s `QFNL000400` on schedule v1+v2 | Added to complete the QF set; names from Event Config R16 `8FNL000700`/`800` (Zaman / Zhu); status `SCHEDULED` |
| SF1 side 2 | `TBD` + `PreviousUnit` → `QFNL000200` / W (was bare `TBD`) |
| SF2 StartList | Both sides `TBD` + `PreviousUnit` → `QFNL000300` / W and `QFNL000400` / W (was empty unit) |
| SF1/SF2 clock | Shifted to 17:15 / 18:15 so QF4 fits at 16:15 |

## Sources in rawData

| Piece | rawData |
|-------|---------|
| PARTIC | `01_Pre-Competiton` |
| Schedule v2 unit overlays | R16 / QF / W finals fragments + Event Config |
| W RESULT + MEDALLISTS + MEDALS | Women’s finals day |
| M QF1 OFFICIAL + QF2 LIVE | Men’s Quarterfinals |
| M R16 W/O + RET | Men’s Round of 16 |
| Schedule v1 skeletons | Event Configuration unit shells (StartList cleared for playback) |
| QF4 names | Event Configuration R16 `8FNL000700` / `8FNL000800` |
