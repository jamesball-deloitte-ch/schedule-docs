# CKT Schedule Tile — FE Component Extension

**Audience:** Frontend (WMR / CIS schedule card)  
**Baseline Figma:** [Cross-sport pages 2.0 — Header / schedule card](https://www.figma.com/design/7R46sxsgqvLb3kbA1BW6cF/Cross-sport-pages-2.0?node-id=27483-256042&m=dev) (`7R46sxsgqvLb3kbA1BW6cF` · `27483:256042`)  
**Product rules:** [schedule-tile-requirements.md](./schedule-tile-requirements.md) · [common](../common/schedule-tile-common.md)  
**API:** [Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule)

This doc maps the **existing baseline card** to what CKT needs. Do not fork a separate cricket-only card unless design ships one — extend the same component with sport variants / slots.

---

## 1. Baseline anatomy (what we already have)

From the selected Figma instance (`Header` → `Card content`):

| Slot (Figma name) | Role today | CKT reuse |
|-------------------|------------|-----------|
| **WMR Schedule cards time & status** | Time pill + status icon + optional medal | Keep. During live, status/progress may show innings (see §3). |
| **Text box → Headline** | Discipline name (e.g. Basketball) | Keep → Cricket / CKT display name. |
| **Text box → Subtext** | Event / phase (e.g. Men’s Semifinal) | Keep → event + phase; group stage may include “Group A” (OSRP). |
| **Right aligned** | Full Results · bookmark · overflow | Unchanged (product chrome). |
| **Results box → WMR Schedule results** | 2 stacked rows: flag · name · **numeric score**; winner chevron | Keep layout; change **score cell** content and row states (§4). |
| **Match info** (in Figma: **hidden**) | Reserved strip under header / around results | **Enable for CKT** — match-situation / first-innings line (§5). |
| **WMR Schedule buttons bar** (hidden) | Extra actions | Out of scope unless product asks. |

Figma annotation on winner chevron: *“Winner indicator doesn't show up on medal events”* — still apply for CKT H2H; hide on pure medal-event layouts if that rule is global.

```
┌─────────────────────────────────────────────────────────────┐
│ [time]  Headline (discipline)              Full Results  … │
│ [status] Subtext (event / phase)                           │
│ [medal?]                                                   │
├─────────────────────────────────────────────────────────────┤
│  Results box                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🏳️ Team A                              score cell A │◀──│ winner
│  │ 🏳️ Team B                              score cell B │   │
│  └─────────────────────────────────────────────────────┘   │
│  Match info  ← enable for CKT (situation / elected)        │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Variant strategy

| Approach | Recommendation |
|----------|----------------|
| New `ScheduleCardCkt` | Avoid unless design diverges heavily |
| Same card + `disciplineCode === 'CKT'` / flavour `h2h-score` | **Preferred** — extend score renderer + Match info |
| Score cell as pluggable `ScoreRenderer` | Strongly preferred — baseline uses simple number; CKT needs string / dual line |

**FE responsibility split**

| Layer | Owns |
|-------|------|
| BE / API | Scores as display strings or structured runs/wickets/overs; `YTB`; `liveCurrentProgress`; `finalResultDescription`; placeholders; WLT |
| FE | Map API → baseline slots; **do not** compose ResultDesc / `#ORG*` templates client-side |

---

## 3. Header extensions (time & status)

### 3.1 Unchanged

- Time from `startDate` **or** `startText` when `hideStartDate` ([common §3.4](../common/schedule-tile-common.md)).
- No “Scheduled” badge.
- Medal icon when `medalFlag` ≠ none.
- Status icon from `scheduleStatus` / after finish `resultStatus` (common).

### 3.2 Live progress (CKT-specific)

When `scheduleStatus` is live-ish (`RUNNING`, break, interrupted) and API provides `liveCurrentProgress`:

| Field | UI |
|-------|-----|
| `liveCurrentProgress.name` | Show as progress label (e.g. **2nd Innings**, optionally with over if BE folded it into `name`) |
| Placement | Prefer under / beside status icon in **time & status**, **or** as secondary line in Match info — pick one per design; do not duplicate. |

Before start / after finish: treat progress as absent (`null`) — do not leave stale innings text.

---

## 4. Results box — competitor rows

Baseline: two rows, each `NOC/flag + name + score`.

### 4.1 Competitors / placeholders

| API | FE |
|-----|-----|
| Confirmed team | Flag + team name (`competitors[]`) |
| Placeholder | No flag (or placeholder glyph per DS); `placeholderOpponents[].name` as-is (`To be determined`, `Second Round Rank n`, …) |
| `NOCOMP` | Follow DS empty/no-competitor pattern if present |

Do not invent TBD copy on FE.

### 4.2 Score cell — replace simple integer

Baseline shows `18` / `16`. For CKT the **same cell** must support:

| State | Display | Source |
|-------|---------|--------|
| Before | Empty / hidden scores | No result yet |
| During — batting | `nnn/n (n.n)` or `nnn/n (nn)` | `competitors[].result` (BE-formatted preferred) |
| During — not yet batted | **Yet to bat** (not a number) | `YTB` / ResultMark → BE string or FE map of known code → OSRP phrase |
| After — regular | Same score format both sides | Final result |
| After — Super Over | Primary score + `SO n/n (…)` (second line or same cell wrap) | When SO periods present |
| IRM / abandoned path | Follow IRM / empty + Match info sentence | Prefer situation line for Abandoned / No Result |

**Typography**

- Winner row: keep baseline **bold name** + winner chevron (`WLT=W`).
- Losing / other: medium weight as today.
- “Yet to bat”: treat as score-slot text (medium), not a fake `0/0`.

**Layout risk:** cricket strings are wider than `18`. Score column must allow shrink/wrap or min-width growth without colliding with names. If Figma has no CKT score variant yet, implement with design tokens and flag for UX review of long strings (`245/8 (50.0)` + `SO 12/1 (1.2)`).

### 4.3 Winner indicator

- Show when `WLT` indicates winner and unit is not under the global “hide on medal events” rule.
- CKT after: always prefer chevron + bold on winner when there is a decisive result; for `TIED` / No Result / Abandoned — **no** winner chevron.

---

## 5. Match info slot (enable for CKT)

Baseline has **Match info** hidden. For CKT, show it when there is copy:

| Phase | Content | API |
|-------|---------|-----|
| During — 1st innings | `First innings: {Team} elected to bat/field` | BE-composed from `ER/TOSS` + `PERIOD=IN1` (requirements §3.4). **Do not** build from raw ODF on FE. |
| After | Match situation sentence | **`extendedResultInfo.finalResultDescription` only** |
| After examples | `India beat Pakistan by 9 wickets` · `… by 44 runs` · Super Over · `Match Abandoned` · `No Result` | BE-interpolated `SC@ResultDesc` |

**Rules**

1. Never build `#ORG1 beat #ORG2 by #SCR …` on the client.
2. If `finalResultDescription` is null/empty after finish, hide Match info (do not fall back to guessing from scores).
3. One line; truncate/ellipsis per DS if overflow.
4. Do not put situation text inside the score column.

---

## 6. Phase → slot matrix

| Slot | Before | During | After |
|------|--------|--------|-------|
| Time / startText | ✓ | ✓ | ✓ (or finished status focus) |
| Status / medal | status as common; medal if any | live + optional `liveCurrentProgress` | result status + medal |
| Headline / Subtext | discipline + event/phase/group | same | same |
| Results rows | teams or placeholders; **no scores** | flags + names + score **or** Yet to bat | scores (+ SO); winner styling |
| Match info | hidden | optional elected line | **`finalResultDescription`** |
| Full Results etc. | as product | as product | as product |

---

## 7. Suggested FE props / mapping (illustrative)

Not a mandated TypeScript contract — align with existing Schedule API types.

```ts
// Baseline row
type ScheduleCompetitorRow = {
  flag?: string;
  name: string;
  isWinner?: boolean;
  /** Baseline: number | string. CKT: "128/5 (20.3)" | "Yet to bat" | "128/5 (20.3) SO 12/1 (1.0)" */
  scoreDisplay?: string | null;
};

type ScheduleCardViewModel = {
  timeLabel: string;           // clock or startText
  status: { icon: string; label?: string };
  medalVisible: boolean;
  headline: string;            // discipline
  subtext: string;             // event / phase / group
  rows: [ScheduleCompetitorRow, ScheduleCompetitorRow] | ScheduleCompetitorRow[];
  liveProgressLabel?: string | null;  // from liveCurrentProgress.name
  matchInfo?: string | null;          // finalResultDescription | elected line
  showMatchInfo: boolean;
};
```

| API | → VM |
|-----|------|
| `competitors[].result` (+ YTB) | `scoreDisplay` |
| `competitors[].result.wlt` | `isWinner` |
| `placeholderOpponents[]` | rows without scores |
| `liveCurrentProgress.name` | `liveProgressLabel` |
| `extendedResultInfo.finalResultDescription` | `matchInfo` (after) |
| toss/elected (BE Match info during; §3.4) | `matchInfo` (during) |

---

## 8. FE checklist (CKT vs baseline)

- [ ] Reuse baseline card; no parallel cricket-only layout without design
- [ ] Score cell accepts **string** (runs/wickets/overs), not only integer
- [ ] Map `YTB` → **Yet to bat** in score slot
- [ ] Super Over: second score fragment in same cell or approved wrap
- [ ] Enable **Match info** for `finalResultDescription` after finish
- [ ] Never compose situation sentence on FE
- [ ] Placeholders: render BE `name`; no client TBD dictionary
- [ ] Optional: `liveCurrentProgress` in status area during live
- [ ] First-innings elected line when BE sends Match info (§3.4)
- [ ] Winner chevron + bold; suppress for tie / abandoned / no result
- [ ] Long score strings: layout QA (desktop + mobile widths)

---

## 9. Design follow-ups

Ask design if missing from the baseline node:

1. Explicit CKT states: Yet to bat, long score, Super Over, Match info with situation text, live innings chip.
2. Placeholder row (no flag).
3. Whether live progress sits in **time & status** or **Match info**.

Until those frames exist, implement against this doc + OSRP copy; visual polish when CKT variants land in the same Figma file.
