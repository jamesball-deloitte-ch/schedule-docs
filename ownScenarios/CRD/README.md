# CRD — Schedule tile freeze (mixed-day playback)

**LogicalDate:** `2026-09-09` (same day as FBL / CLB / ARC / SQU freezes)  
**Now (after full ingest):** `2026-09-09T12:00:00+02:00`  
**Folder:** [`01_Schedule_Tile_Mixed_Day`](01_Schedule_Tile_Mixed_Day)  
**Ingest:** filename order (timestamp prefix).

Bodies **copied** from `rawData/CRD` (OG2028-ITL), then remapped to `2026-09-09`. Men’s FNL from HappyPath; Women’s Road Race interrupt from Exceptionals. Several `DT_SCHEDULE_UPDATE` versions show before → live (+ `DT_CURRENT`) → finished + medals.

OLY grouping: CRD has **no** row in `olympic-grouping-rules.csv` → **no `groupId`**.  
CC `@Unit`: **14** codes — **0× `Schedule=S`**, 13× `Y`, 1× `N` (venue `OTHR`, not in feed).

---

## Playback

| Step | File prefix | Message | Now | What to check |
|------|-------------|---------|-----|---------------|
| 1 | `080000000` | `DT_PARTIC_UPDATE` | 08:00 | athletes loaded |
| 2 | `080001000` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | **all 4 FNL SCHEDULED** (+ MEET / VICT / UNSCHEDULED) — before |
| 3 | `090000000` | `DT_SCHEDULE_UPDATE` **v2** | 09:00 | Women’s ITT **RUNNING**; others still SCHEDULED |
| 4 | `110000000` | `DT_SCHEDULE_UPDATE` **v3** | 11:00 | W ITT still RUNNING; Men’s RR **RUNNING** |
| 5 | `110001000` | `DT_CURRENT` | 11:00 | Men’s RR live race context (**before** medals) |
| 6 | `120000000` | `DT_SCHEDULE_UPDATE` **v4** | 12:00 | W ITT **FINISHED**; M ITT GETTING_READY; W RR **INTERRUPTED**; M RR RUNNING |
| 7 | `120001000` | `DT_MEDALLISTS` | 12:00 | Women’s ITT G/S/B on tile |
| 8 | `120002000` | `DT_MEDALS` | 12:00 | discipline standings |

Stop after step 2 for a pure “before” day. Full ingest ends at step 8 (`now = 12:00`).

---

## After full ingest (`now = 12:00`)

### Competition tiles (WMR default list)

| Tile | RSC | Status | Source pack | Expect |
|------|-----|--------|-------------|--------|
| Women’s ITT | `CRDWTT----------------FNL-000100--` | FINISHED | HappyPath | Medallists: Zabelinskaya UZB, Lach POL, van de Velde BEL. **No score.** `medalFlag=1` |
| Men’s ITT | `CRDMTT----------------FNL-000100--` | GETTING_READY | HappyPath | Before badge; medal marker |
| Women’s Road Race | `CRDWRR----------------FNL-000100--` | **INTERRUPTED** | Exceptionals | Exceptional badge; not live highlight |
| Men’s Road Race | `CRDMRR----------------FNL-000100--` | RUNNING | HappyPath | Live highlight; `DT_CURRENT` already ingested; **no score** |

### Filter-test rows (every SCHEDULE version)

| RSC | Status | Expect |
|-----|--------|--------|
| `CRDGGEN---------------MEET000200--` | SCHEDULED | Team Managers' Meeting TT — **WMR hide** / CIS may keep |
| `CRDWTT----------------VICTMEDAL---` | SCHEDULED | Victory Ceremony — **WMR hide** / CIS keep |
| `CRDGGEN---------------MEET000500--` | **UNSCHEDULED** | **Never listed** |

### Redirects

Every competition tile → unit-results of **that** RSC. No override.

**Acceptance criteria:** [AC.feature](AC.feature)

---

## Not covered

| Case | Why |
|------|-----|
| `DELAYED`, `CANCELLED` | Not in CRD rawData schedule |
| `POSTPONED`, `RESCHEDULED` | Men Exceptionals only (outside men=Happy / women=Exc split) |

---

## Sources in rawData

| Freeze piece | rawData |
|--------------|---------|
| PARTIC | `01_CRD_PT1_HappyPath/01_Pre-Competition` `DT_PARTIC_UPDATE` |
| SCHEDULE shell + v1 SCHEDULED | same `DT_SCHEDULE_UPDATE` v1 |
| W ITT RUNNING | `01_…/02_Day_1_…/01_Women_…` `00008_*` |
| W ITT FINISHED | `…` `00254_*` |
| M ITT GETTING_READY | `01_…/02_Day_1_…/02_Men_…` `00270_*` |
| W RR INTERRUPTED | `02_CRD_PT1_Exceptionals/03_Day_2_…` `00847_*` |
| M RR RUNNING | `01_…/04_Day_3_…` `01157_*` |
| M RR CURRENT | `…` `01159_*` |
| W ITT MEDALLISTS + MEDALS | `…/01_Women_…` `00259_*`, `00261_*` |
