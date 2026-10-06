# SQU — Schedule tile freezes

Two playbacks for CIS / WMR schedule tiles. Same LogicalDate `2026-09-09`. Ingest each folder in filename order.

| Folder | Intent |
|--------|--------|
| [`01_Schedule_Tile_Mixed_Day`](01_Schedule_Tile_Mixed_Day) | Mixed / edge day: women’s `NOCOMP` finals, W/O + RET, live QF, mixed SF TBD |
| [`02_Schedule_Tile_Women_Finals_Men_QF`](02_Schedule_Tile_Women_Finals_Men_QF) | Optimistic: women full G/S/B podium; men mid-QF, mixed SF TBD, one RET |

**Acceptance criteria:** [AC.feature](AC.feature)

**Grouping (test overlay):** [`docs/grouping/squ-sim-grouping-rules.csv`](../../docs/grouping/squ-sim-grouping-rules.csv) — `GroupId = {PhaseRSC}` (one group per gender+event+phase across sessions). Paris baseline has no SQU grouping; this CSV is for sim/WMR grouped-card tests only.

Phases are CC `Schedule=N` — no phase cards. Details and fabricated notes live in each folder’s README.
