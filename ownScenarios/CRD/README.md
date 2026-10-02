# CRD — Schedule tile freeze (mixed-day playback)

**LogicalDate:** `2026-09-09` (same day as FBL / CLB / ARC / SQU freezes)  
**Now (after full ingest):** `2026-09-09T12:00:00+02:00`  
**Folder:** [`01_Schedule_Tile_Mixed_Day`](01_Schedule_Tile_Mixed_Day)  
**Ingest:** filename order (timestamp prefix).

Bodies **copied** from `rawData/CRD` (OG2028-ITL), then remapped to `2026-09-09`. Men’s FNL from HappyPath; Women’s Road Race interrupt from Exceptionals. Several `DT_SCHEDULE_UPDATE` versions show before → live (+ `DT_CURRENT`) → finished + medals.

OLY grouping: CRD has **no** row in `olympic-grouping-rules.csv` → **no `groupId`**.  
CC `@Unit`: **14** codes — **0× `Schedule=S`**, 13× `Y`, 1× `N` (venue `OTHR`, not in feed).

**Country filter:** each of the four FNL tiles must expose the **full** unit start list in `competitors[]` (hidden on the card). Source = `DT_RESULT` with `ResultStatus=START_LIST` per unit RSC. `DT_ENTRIES` (event RSC) is also ingested for each event; it does **not** replace unit START_LIST for schedule `competitors[]`.

---

## Playback

| Step | File prefix | Message | Now | What to check |
|------|-------------|---------|-----|---------------|
| 1 | `080000000` | `DT_PARTIC_UPDATE` | 08:00 | athletes loaded |
| 2 | `080001000` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | **all 4 FNL SCHEDULED** (+ MEET / VICT / UNSCHEDULED) — before |
| 3 | `080010000`–`080013000` | `DT_ENTRIES` ×4 events | 08:00 | W/M ITT + W/M RR event entries (35 / 35 / 95 / 90) |
| 4 | `080014000`–`080017000` | `DT_RESULT` **START_LIST** ×4 FNL | 08:00 | **full** `competitors[]` on each unit (country filter) |
| 5 | `090000000` | `DT_SCHEDULE_UPDATE` **v2** | 09:00 | Women’s ITT **RUNNING**; others still SCHEDULED |
| 6 | `110000000` | `DT_SCHEDULE_UPDATE` **v3** | 11:00 | W ITT still RUNNING; Men’s RR **RUNNING** |
| 7 | `110000500` | `DT_RESULT` **LIVE** Men’s RR | 11:00 | live unit results (90 riders) before `DT_CURRENT` |
| 8 | `110001000` | `DT_CURRENT` | 11:00 | Men’s RR live race context (**before** medals) |
| 9 | `120000000` | `DT_SCHEDULE_UPDATE` **v4** | 12:00 | W ITT **FINISHED**; M ITT GETTING_READY; W RR **INTERRUPTED**; M RR RUNNING |
| 10 | `120000500` | `DT_RESULT` **OFFICIAL** Women’s ITT | 12:00 | full official ranking; top3 = medallists |
| 11 | `120001000` | `DT_MEDALLISTS` | 12:00 | Women’s ITT: `result.medal` on G/S/B **inside** full list |
| 12 | `120002000` | `DT_MEDALS` | 12:00 | discipline standings |

Stop after step 2 for schedule-only “before”. After step 4 every FNL has full `competitors[]`. Full ingest ends at step 12 (`now = 12:00`).

---

## After full ingest (`now = 12:00`)

### Competition tiles (WMR default list)

| Tile | RSC | Status | Source pack | Expect |
|------|-----|--------|-------------|--------|
| Women’s ITT | `CRDWTT----------------FNL-000100--` | FINISHED | HappyPath | **Full** start-list `competitors[]` + medals on Zabelinskaya UZB, Lach POL, van de Velde BEL. Card shows only those three. **No score.** `medalFlag=1` |
| Men’s ITT | `CRDMTT----------------FNL-000100--` | GETTING_READY | HappyPath | Before badge; medal marker; **full** `competitors[]` (no medals yet) |
| Women’s Road Race | `CRDWRR----------------FNL-000100--` | **INTERRUPTED** | Exceptionals | Exceptional badge; not live highlight; **full** `competitors[]` |
| Men’s Road Race | `CRDMRR----------------FNL-000100--` | RUNNING | HappyPath | Live highlight; `DT_CURRENT` already ingested; **full** `competitors[]`; **no score** |

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
| PARTIC | `01_Pre-Competition` `DT_PARTIC_UPDATE` (existing freeze body) |
| SCHEDULE shell + v1 SCHEDULED | existing freeze / schedule remaps |
| W ITT ENTRIES | `02_Day_1_Time_Trial/01_Women_…` `00003_*` `DT_ENTRIES` |
| M ITT ENTRIES | `02_Day_1_Time_Trial/02_Men_…` `00266_*` `DT_ENTRIES` |
| W RR ENTRIES | `03_Day_2_Women_Road_Race/…` `00599_*` `DT_ENTRIES` |
| M RR ENTRIES | `04_Day_3_Men_Road_Race/…` `01152_*` `DT_ENTRIES` |
| W ITT START_LIST | `02_Day_1_…/01_Women_…` `00005_*` `DT_RESULT` START_LIST |
| M ITT START_LIST | `02_Day_1_…/02_Men_…` `00268_*` `DT_RESULT` START_LIST |
| W RR START_LIST | `03_Day_2_…` `00601_*` `DT_RESULT` START_LIST |
| M RR START_LIST | `04_Day_3_…` `01154_*` `DT_RESULT` START_LIST |
| M RR LIVE | `04_Day_3_…` `01158_*` `DT_RESULT` LIVE (pairs with CURRENT `01159`) |
| W ITT OFFICIAL | `02_Day_1_…/01_Women_…` `00256_*` `DT_RESULT` OFFICIAL |
| W ITT MEDALLISTS + MEDALS | existing freeze (`00259_*`, `00261_*` remap) |
| M ITT GETTING_READY / W RR INTERRUPTED / M RR RUNNING + CURRENT | existing freeze |
