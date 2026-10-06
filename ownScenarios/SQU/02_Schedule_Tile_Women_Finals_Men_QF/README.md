# SQU — Schedule tile freeze 02 (women done, men mid-QF)

**LogicalDate:** `2026-09-09`  
**Folder:** [`02_Schedule_Tile_Women_Finals_Men_QF`](.)  
**Now (after full ingest):** `2026-09-09T14:30:00+02:00`  
**Ingest:** filename order (timestamp prefix).

Optimistic counterpart to [`01_Schedule_Tile_Mixed_Day`](../01_Schedule_Tile_Mixed_Day): Women’s Singles finished with a full podium; Men’s Singles mid Quarter-finals with live score and mixed SF TBD.

Phases are CC `Schedule=N` — **no phase cards**.

---

## Playback

| Step | File prefix | Message | Now | What to check |
|------|-------------|---------|-----|---------------|
| 1 | `080000000` | `DT_PARTIC_UPDATE` | 08:00 | athletes loaded |
| 2 | `080001000` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | **11 RSCs, all SCHEDULED, no StartList** |
| 3 | `143000000` | `DT_SCHEDULE_UPDATE` **v2** | 14:30 | women SF+FNL finished; men QF mid + mixed SF TBD |
| 4 | `143001*` | `DT_RESULT` | 14:30 | W SF + FNL scores; M RET; M QF1 OFFICIAL; M QF2 LIVE (games won) |
| 5 | `143010000` | `DT_MEDALLISTS` | 14:30 | Women’s G / S / B |
| 6 | `143011000` | `DT_MEDALS` | 14:30 | POL / JPN / FRA (women only) |

---

## After full ingest (`now = 14:30`)

### Women’s Singles — event complete

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| SF1 | `SQUWSINGLES-----------SFNL000100--` | FINISHED | Lamb **0** – Watanabe **3** |
| SF2 | `SQUWSINGLES-----------SFNL000200--` | FINISHED | Otrzasek **3** – Lincou **0** |
| Bronze | `SQUWSINGLES-----------FNL-000200--` | FINISHED | Lamb **0** – Lincou **3**, `medalFlag=3` |
| Gold | `SQUWSINGLES-----------FNL-000100--` | FINISHED | Watanabe **0** – Otrzasek **3**, `medalFlag=1` |
| Medallists | `DT_MEDALLISTS` | OFFICIAL | Gold Otrzasek POL; Silver Watanabe JPN; Bronze Lincou FRA |

### Men’s Singles — mid QF + mixed TBD

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| R16 | `…8FNL000500--` | FINISHED | Lau **3** – Rodriguez **1** **RET** (`invalidResultMark`) |
| QF1 | `…QFNL000100--` | FINISHED | Adegoke **3** – Zhou **0** |
| QF2 | `…QFNL000200--` | **RUNNING** | Nasser **1** – Wilhelmi **1** (`liveFlag`; no current-game chrome) |
| QF3 | `…QFNL000300--` | GETTING_READY | Lau vs Farkas (no score) |
| QF4 | `…QFNL000400--` | SCHEDULED | Zaman vs Zhu (no score) |
| SF1 | `…SFNL000100--` | SCHEDULED | Adegoke vs **TBD** (mixed placeholder; do not compose Winner 10) |
| SF2 | `…SFNL000200--` | SCHEDULED | Both unknown → **no** H2H rows |

### Grouping (test CSV `{PhaseRSC}`)

Upload [`docs/grouping/squ-sim-grouping-rules.csv`](../../../docs/grouping/squ-sim-grouping-rules.csv). Singleton groups are dropped.

| `groupId` | Members | What to check |
|-----------|---------|---------------|
| *(none)* | R16 `8FNL000500` (`SQU01`) | Ungrouped RET tile |
| `SQU05` | QF1 FINISHED + QF2 RUNNING | Group `isLive`; live child = score + `liveFlag` |
| `SQU06` | QF3 GETTING_READY + QF4 SCHEDULED | Before-start pair |
| `SQU07` | Women’s SF1 + SF2 | Both finished |
| `SQU08` | Men’s SF1 + SF2 | Mixed TBD on SF1; SF2 phase/event only |
| `SQU09` | Women’s Bronze + Gold | `hasMedals` |

### Redirects

Every tile → unit-results of **that** RSC (no overrides).

---

## Fabricated

| Piece | Note |
|-------|------|
| Men’s QF1 `DT_RESULT` OFFICIAL | Raw dump ends QF1 as `2DSQ`; replaced with clean **3–0** Adegoke–Zhou for an optimistic finished QF |
| `DT_MEDALS` | Women-only standings aligned to `DT_MEDALLISTS` (POL / JPN / FRA) — no men’s medals in this freeze |
| Schedule v1/v2 shells | Unit set + times remapped to `2026-09-09`; SF placeholders with `PreviousUnit` |

## Sources in rawData

| Piece | rawData |
|-------|---------|
| PARTIC | `00_Event_Configuration` full `DT_PARTIC_UPDATE` |
| W SF1 / SF2 OFFICIAL | `07_Women's Semifinals` |
| W Bronze / Gold OFFICIAL | `08_Women's Bronze…` / `09_Women's Gold…` |
| W MEDALLISTS | `09_Women's Gold…` OFFICIAL |
| M R16 RET | `02_Men's Round of 16` `8FNL000500` |
| M QF2 LIVE G3 | `04_Men's Quarterfinals` |
| QF StartList names | Event Config / QF day bracket |
