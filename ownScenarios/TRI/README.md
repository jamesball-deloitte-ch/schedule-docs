# TRI — Schedule tile freeze (mixed-day playback)

**LogicalDate:** `2026-09-09` (same day as CRD / CLB / ARC / SQU freezes)  
**Now (after full ingest):** `2026-09-09T12:00:00+02:00`  
**Folder:** [`01_Schedule_Tile_Mixed_Day`](01_Schedule_Tile_Mixed_Day)  
**Ingest:** filename order (timestamp prefix).

**Intent:** one mixed day — **Women’s Individual LIVE**, **Men’s Individual FINISHED + medallists**, **Mixed Relay FINISHED + medallists**.

Bodies **copied** from `rawData/TRI` (OG2028-ITL), remapped to `2026-09-09`, with unit start times collapsed onto that day. Pack: [`docs/TRI/schedule-tile-requirements.md`](../../docs/TRI/schedule-tile-requirements.md).

OLY grouping: TRI has **no** row in `olympic-grouping-rules.csv` → **no `groupId`**.  
CC `@Unit` (`OG2028` v1.6.0): **27** codes — **0× `Schedule=S`**, 26× `Y`, 1× `N`.

**Country filter:** each competition tile keeps the **full** unit start list in `competitors[]` (from `DT_RESULT` START_LIST / later statuses). Card UI does not render the peloton / team grid — only medallists after finish (or live highlight for women).

---

## Playback

| Step | File prefix | Message | Now | What to check |
|------|-------------|---------|-----|---------------|
| 1 | `080000000` | `DT_PARTIC` | 08:00 | athletes with `@GivenName`/`@FamilyName` on Participant (from W/M start lists) |
| 2 | `080001000` | `DT_PARTIC_TEAMS` | 08:00 | mixed-relay teams |
| 3 | `080002000`–`080004000` | `DT_ENTRIES` ×3 | 08:00 | W / M / X event entries |
| 4 | `080010000` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | all three finals **SCHEDULED** (+ DRAW / MEET / VICT) — before |
| 5 | `080020000`–`080022000` | `DT_RESULT` **START_LIST** ×3 | 08:00 | full `competitors[]` per unit |
| 6 | `090000000` | `DT_SCHEDULE_UPDATE` | 09:00 | Men’s Individual **FINISHED** |
| 7 | `090001000` | `DT_RESULT` **OFFICIAL** Men | 09:00 | full ranking; top3 = medallists |
| 8 | `090002000` | `DT_MEDALLISTS` Men | 09:00 | G/S/B on Knabl AUT / Pevtsov AZE / Wright BAR |
| 9 | `100000000` | `DT_SCHEDULE_UPDATE` | 10:00 | Mixed Relay **FINISHED** |
| 10 | `100001000` | `DT_RESULT` **OFFICIAL** Mixed | 10:00 | team ranking |
| 11 | `100002000` | `DT_MEDALLISTS` Mixed | 10:00 | G/S/B on ITA / GER / SUI **teams** |
| 12 | `110000000` | `DT_SCHEDULE_UPDATE` | 11:00 | Women’s Individual **RUNNING** |
| 13 | `110001000` | `DT_RESULT` **LIVE** Women | 11:00 | live results; **no** women’s medallists in freeze |
| 14 | `120000000` | `DT_MEDALS` | 12:00 | standings = **Men + Mixed only** (no Women) |

Stop after step 4 for schedule-only “before”. After step 5 every FNL has full `competitors[]`. Full ingest ends at step 14 (`now = 12:00`).

---

## After full ingest (`now = 12:00`)

### Competition tiles (WMR default list)

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| Women’s Individual | `TRIWOLYMPIC-----------FNL-000100--` | **RUNNING** | Live highlight; full `competitors[]`; **no** medallists; **no** race score on tile; `medalFlag=1` |
| Men’s Individual | `TRIMOLYMPIC-----------FNL-000100--` | **FINISHED** | Full start list + medals on Knabl AUT, Pevtsov AZE, Wright BAR (athlete names); card shows medallists only; no score |
| Mixed Relay | `TRIXTEAM4-------------FNL-000100--` | **FINISHED** | Full team start list + medals on Italy / Germany / Switzerland (**team names**); no score |

### Filter-test rows (present in schedule v1)

| RSC | Expect |
|-----|--------|
| `TRIGGEN---------------DRAW*` / `MEET*` | Non-competition — **omit** from schedule list per pack / common |
| `TRI*VICTMEDAL---` | Victory Ceremony — **WMR hide** / CIS keep |

### Redirects

Every competition tile → unit-results of **that** RSC. No override. Examples:

| Surface | Women’s Individual |
|---------|-------------------|
| CIS | `/en/OG2028/TRI/W/OLYMPIC-----------/FNL-/000100--/results` |
| WMR | `/en/la28/results/unit/triwolympic-----------fnl-000100--` |

**Acceptance criteria:** [AC.feature](AC.feature) ([DRES-32642](https://dgplatform.atlassian.net/browse/DRES-32642)) · FE map: [`docs/TRI/schedule-tile-fe-score.md`](../../docs/TRI/schedule-tile-fe-score.md)

---

## Consistency (gate 4b)

| Check | Result |
|-------|--------|
| `DT_MEDALLISTS` before `DT_MEDALS` | Yes (`090002` / `100002` then `120000`) |
| Men medallists = OFFICIAL Rank 1–3 | Knabl AUT, Pevtsov AZE, Wright BAR |
| Mixed medallists = OFFICIAL Rank 1–3 | ITA / GER / SUI teams |
| `DT_MEDALS` scope | Fabricated: FinishedEvents=2, **no Women** rows (women still LIVE) |
| Schedule=S | **0** units — none to include |

---

## Not covered

| Case | Why |
|------|-----|
| `DT_CURRENT` | Not present in `rawData/TRI` — live via `DT_RESULT` LIVE |
| Women’s medallists / finish | Intentionally left LIVE |
| Tied medals (>3 rows) | Not in this HappyPath dump |
| `DELAYED` / `INTERRUPTED` | Available under Exceptionals folders — not selected for this mixed day |

---

## Sources in rawData

| Freeze piece | rawData |
|--------------|---------|
| PARTIC (fabricated) | Built from W/M START_LIST descriptions (`02_…/02_01`, `03_…/03_01`) — raw only has 7× thin `DT_PARTIC_UPDATE` |
| PARTIC_TEAMS | `00_Initial_Messages/00001_*` |
| ENTRIES W/M/X | `00_Initial_Messages/00002`–`00004` |
| SCHEDULE shell (all SCHEDULED) | `00_Initial_Messages/00005_*` |
| Women RUNNING | `02_…/02_01` `…155656761` `DT_SCHEDULE_UPDATE` |
| Women LIVE | `02_…/02_01` `…160000590` `DT_RESULT` LIVE |
| Women START_LIST | `02_…/02_01` `…155530525` |
| Men FINISHED + OFFICIAL + MEDALLISTS | `03_…/03_01` `…155328050` / `…155359843` / `…155414934` |
| Men START_LIST | `03_…/03_01` `…153808176` |
| Mixed FINISHED + OFFICIAL + MEDALLISTS | `05_…/05_01` `…193622791` / `…193652231` / `…193707215` |
| Mixed START_LIST | `05_…/05_01` `…192425406` |
| DT_MEDALS | **Fabricated** (not copied — raw files include Women) |

---

## Fabricated files

| File | Reason |
|------|--------|
| `01_Schedule_Tile_Mixed_Day/2026-09-09-080000000-DT_PARTIC--TRI--------------------------------.xml` | Bulk athletes from W/M START_LIST (rawData only has 7 thin `DT_PARTIC_UPDATE`). Names on **`Participant/@GivenName` / `@FamilyName`** (ODF/CRD shape) — first draft wrongly used nested `<Description>` so BE saw empty names |
| `01_Schedule_Tile_Mixed_Day/2026-09-09-120000000-DT_MEDALS--TRI--------------------------------.xml` | Standings for Men + Mixed Relay only; exclude Women (still LIVE) |
