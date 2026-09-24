# CKT — Schedule tile freeze (mixed multi-day)

**LogicalDays:** `2026-09-06` … `2026-09-09` (4 days)  
**Now (after full ingest):** `2026-09-09T15:15:00+02:00`  
**Folder:** [`01_Schedule_Tile_Mixed_Days`](01_Schedule_Tile_Mixed_Days)  
**Ingest:** filename order (timestamp prefix).

Bodies from `rawData/CKT` (OG2028-ITL), dates remapped. Team identities and scores unchanged.

## CC `@Unit` (OG2028 v1.6.0)

| Schedule | Count (CKT units) |
|----------|-------------------|
| **Y** | All competition matches + MEET + VICT |
| **N** | Phases + venue `OTHRFRG` |
| **S** | **0** |

`TMRY*` is `Y` in CC but **not present** in `DT_SCHEDULE` feeds. Listing = `Schedule=Y` units from the feed.  
OLY grouping: CKT has **no** row in `olympic-grouping-rules.csv` → **no `groupId`**.

## Team bootstrap (required)

1. `DT_PARTIC_UPDATE` — athletes  
2. `DT_PARTIC_TEAMS_UPDATE` — 12 team codes (`Type=T`)  
3. `DT_ENTRIES` `CKTMT20` + `CKTWT20` — who is in which team (GROUP / Composition)  
4. Then schedule / results  
5. End of day: **`DT_MEDALLISTS` → `DT_MEDALS`** (never reverse)

---

## Playback

| Step | File prefix | Message | Now | What to check |
|------|-------------|---------|-----|---------------|
| 1–3 | `080000`–`080003` | PARTIC + TEAMS + ENTRIES ×2 | 08:00 | teams / members loaded |
| 4 | `080004` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | 4-day shell, all competition units **SCHEDULED** |
| 5 | `080010*` | `DT_RESULT` finished (W + M GP2) | 08:00 | scores ready for earlier days |
| 6 | `090000` | `DT_SCHEDULE_UPDATE` **v2** | 09:00 | W `GP1A000200` **RUNNING**; earlier days FINISHED |
| 7 | `090001` | `DT_RESULT` LIVE Super Over | 09:00 | `PERIOD=SO1IN2`, scores `nnn/n` |
| 8 | `100000` | `DT_RESULT` Bronze OFFICIAL | 10:00 | `WON_WKT` |
| 9 | `143000` | `DT_SCHEDULE_UPDATE` **v3** | 14:30 | Gold **RUNNING** |
| 10 | `143001` | `DT_RESULT` Gold LIVE | 14:30 | `PERIOD=IN2`, IN1 side had **YTB** |
| 11 | `151000` | `DT_RESULT` Gold OFFICIAL | 15:10 | `FINAL_RESULT=WON_RUN` → *New Zealand beat South Africa by 145 runs* |
| 12 | `151001` | `DT_SCHEDULE_UPDATE` **v4** | 15:10 | Gold **FINISHED** |
| 13 | `151010` | `DT_MEDALLISTS` | 15:10 | Men G/S/B (NZL / RSA / AUS) |
| 14 | `151011` | `DT_MEDALS` | 15:10 | standings **after** medallists — **men-only**, aligned with medallists |

Stop after step 4 for a pure “before” day. Full ingest ends at step 14 (`now = 15:15`).

---

## Day map (`schedulesPerDay`)

### 2026-09-06 — Women’s group (finished)

| RSC | Status | Expect |
|-----|--------|--------|
| `CKTWT20---------------GP1A000100--` | FINISHED | AUS vs IND · `WON_WKT` · scores ~87/2 vs 89/1 · `finalResultDescription` (India beat Australia by 9 wickets) |
| `CKTWT20---------------GP1B000100--` | FINISHED | NZL vs RSA · `WON_RUN` |

### 2026-09-07 — Men’s Second Round (finished)

| RSC | Status | Expect |
|-----|--------|--------|
| `CKTMT20---------------GP2-000100--` | FINISHED | NZL vs PAK · `WON_WKT` |
| `CKTMT20---------------GP2-000200--` | FINISHED | RSA vs GBR · `WON_WKT` |
| `CKTMT20---------------GP2-000300--` | FINISHED | NZL vs AUS · `WON_WKT` |

### 2026-09-08 — Men’s Second Round (finished, incl. tie)

| RSC | Status | Expect |
|-----|--------|--------|
| `CKTMT20---------------GP2-000400--` | FINISHED | RSA vs IND · `WON_RUN` |
| `CKTMT20---------------GP2-000500--` | FINISHED | GBR vs AUS · `WON_WKT` |
| `CKTMT20---------------GP2-000600--` | FINISHED | PAK vs IND · **`MATCH TIED`** + multi Super Over scores |

### 2026-09-09 — NOW (after full ingest)

| RSC | Status | Expect |
|-----|--------|--------|
| `CKTWT20---------------GP1A000200--` | **RUNNING** | IND vs BAR · Super Over live (`SO1IN2`) — raw dump never reached OFFICIAL |
| `CKTMT20---------------FNL-000200--` | FINISHED | Bronze **PAK** vs AUS · `WON_WKT` · `medalFlag=3` |
| `CKTMT20---------------FNL-000100--` | FINISHED | Gold NZL vs RSA · **`WON_RUN`** · `finalResultDescription` · `medalFlag=1` · medallists NZL / RSA / **PAK** |
| `CKTMT20---------------VICTMEDAL---` | SCHEDULED | Victory — **WMR hide** / CIS may keep |

Filter rows in every schedule version: `CKTGGEN…MEET000100` SCHEDULED; gender `MEET` **UNSCHEDULED** (never listed).

### Mid-playback (`now = 14:30`, stop before `151000`)

Gold still **RUNNING** with `liveCurrentProgress` **IN2**, scores `164/9` vs `19/0` (YTB appeared in IN1 for RSA).

---

## Redirects

| Surface | Example |
|---------|---------|
| CIS | `/en/OG2028/CKT/M/T20---------------/FNL-/000100--/results` |
| WMR | `/en/los-angeles-2028/results/ckt/mck/final/000100--` |

Href does not change by before / during / after.

**Acceptance criteria:** [AC.feature](AC.feature)

---

## Medals consistency

| Source | Content |
|--------|---------|
| `DT_MEDALLISTS` `CKTMT20` | NZL gold, RSA silver, **PAK** bronze |
| `DT_MEDALS` | **Same only** — `LastEvent=CKTMT20`, `FinishedEvents=1` / `TotalEvents=2`, no W medals |

**Fabricated:** `DT_MEDALS` (aligned to men’s medallists). Bronze medallist set to **PAK** to match bronze `DT_RESULT` (`WON_WKT`, PH_TEAM Pos1=PAK) — raw dump had a later AUS medallists flip that disagreed with the result.

**Fabricated on gold OFFICIAL `DT_RESULT`:** raw dump ended as `NO RESULT` (rain) with both `WLT=T` and RSA `19/0` (innings not closed). Replaced with `WON_RUN` + `PH_TEAM` NZL/RSA + `SCORE=145`, `WLT` W/L, `Rank` 1/2, and RSA score **`19/10`** (all out) so BE does not treat the match as a draw/incomplete.

---

## Not covered / raw limits

| Case | Why |
|------|-----|
| Men’s Group Stage / Women’s GP2–FNL | Not in this `rawData/CKT` dump |
| Women’s `DT_MEDALLISTS` | Out of scope for this freeze |
| W `GP1A000200` OFFICIAL | Dump ends mid Super Over → left **RUNNING** on 09-09 |
| `Schedule=S` | None in CC for CKT |

---

## Sources in rawData

| Freeze piece | rawData |
|--------------|---------|
| PARTIC / TEAMS / ENTRIES / schedule shell | `01_Pre-Competition` (+ M07 rich schedule for StartLists) |
| W finished | `02_Group Stage Women` W01 / W02 |
| W Super Over LIVE | `02_…/W03` |
| M GP2 | `06_Second Round Men` M07–M12 |
| Bronze / Gold / MEDALLISTS | `07_Medal Matches Men` M13 / M14 |
| MEDALS | **Fabricated** (aligned to men’s medallists) |
