# Schedule Grouping

Greenfield backend spec for assigning schedule event units into UI groups.

**Audience:** backend rebuilding Schedule after migration (new language / stack).  
**Consumers:** WMR Daily Schedule (Grouped Unit Card), CIS.

**Sources:**
- [Grouping](https://dgplatform.atlassian.net/wiki/spaces/M/pages/1685717676/Grouping) — CSV schema, tokens, management API
- [Schedule - daily schedule](https://dgplatform.atlassian.net/wiki/spaces/M/pages/2586509406/Schedule+-+daily+schedule) — historical response shape
- [Grouping for schedule](https://dgplatform.atlassian.net/wiki/spaces/WLCR/pages/3242590237/Grouping+for+schedule) — discipline rule baseline

---

## 1. Goal

Given a list of schedule **units** for a competition (optionally filtered by day), produce:

1. Each unit optionally annotated with `groupId`
2. A sibling `groups[]` array describing each group (title, subtitle, live/medal flags, …)

Configuration MUST be changeable at runtime via CSV upload — no redeploy.

---

## 2. API surface

### 2.1 Public schedule response (target contract)

Extend the existing schedule payload (HTTP snapshot + SSE) with:

| Field | Where | Meaning |
|-------|--------|---------|
| `groups` | top-level array | One entry per distinct resolved group id among units in this response |
| `groupId` | on each unit | Resolved group key, or omit / `null` / `""` when unit is not grouped |

`groups[].id` MUST equal `units[].groupId` for members of that group.

Example (MiCo shape — keep this contract):

```json
{
  "groups": [
    {
      "isLive": false,
      "id": "SBD01_SBDMBA----------------QUAL--------",
      "startDate": "2026-02-05T19:30:00+01:00",
      "hasMedals": false,
      "hasWarnings": false,
      "title": "Snowboard",
      "subTitle": "Men's Snowboard Big Air",
      "unitsCount": 3,
      "type": "phase"
    },
    {
      "isLive": false,
      "id": "LUGTC_LUGWSINGLES-----------TRNO--------",
      "startDate": "2026-02-05T17:00:00+01:00",
      "hasMedals": false,
      "hasWarnings": false,
      "title": "Luge",
      "subTitle": "Women's Singles Official Training",
      "unitsCount": 2,
      "type": "phase"
    }
  ],
  "schedules": [
    {
      "rsc": "LUGWSINGLES-----------TRNO000100--",
      "sessionCode": "LUGTC",
      "groupId": "LUGTC_LUGWSINGLES-----------TRNO--------",
      "discipline": "LUG",
      "disciplineName": "Luge",
      "phaseCode": "LUGWSINGLES-----------TRNO--------",
      "phaseName": "Women's Singles Official Training",
      "startDate": "2026-02-05T17:00:00+01:00",
      "liveFlag": false,
      "medalFlag": "0",
      "scheduleStatus": "SCHEDULED"
    }
  ]
}
```

> Naming: use whatever top-level unit array the LA28 API already uses (`schedules` / `units`). Grouping does not nest units inside `groups[]` — FE joins by `groupId`.

### 2.2 Management API

| Method | Path | Body | Success |
|--------|------|------|---------|
| `POST` | `/{competition}/schedules/management/api/rules` | raw CSV text (header + rows) | `204` |

Behaviour: **full replace** of the active rule set for that competition/feed. Persist in DB (or equivalent). Next schedule projection rebuild MUST use the new rules.

Optional (nice to have): `GET` same path returning current CSV.

---

## 3. CSV rule format

Header (required):

```text
Discipline,Gender,Event,Phase,Unit,Enabled,GroupId,GroupSubTitle,GroupType
```

| Column | Match / role |
|--------|----------------|
| `Discipline` | Unit discipline code (`LUG`, `SBD`, …) or `*` |
| `Gender` | Gender code (`M`/`W`/`X`) or `*` |
| `Event` | Event code / event RSC fragment or `*` |
| `Phase` | Phase code (`TRNO`, `QUAL`, `FNL-`, …) or `*` — values ending with `-` are **prefix** matchers |
| `Unit` | Unit RSC / unit number fragment or `*` |
| `Enabled` | `TRUE` / `FALSE` — `FALSE` rows are ignored |
| `GroupId` | Template for group key (tokens below). Empty + `Enabled=TRUE` ⇒ **do not group** |
| `GroupSubTitle` | Template for group subtitle (`{Event}` / `{Phase}` / `{Location}`) |
| `GroupType` | `discipline` \| `event` \| `phase` \| `location` |

### 3.1 GroupId tokens

| Token | Resolve from unit |
|-------|-------------------|
| `{Session}` | `sessionCode` |
| `{EventRSC}` | Event RSC (e.g. `SBDMBA----------------`) |
| `{PhaseRSC}` | Phase RSC / `phaseCode` full id (e.g. `SBDMBA----------------QUAL--------`) |
| `{DisciplineRSC}` | Discipline RSC |
| `{LocationCode}` | Location / court code |

Templates may concatenate literals, e.g. `{Session}_{PhaseRSC}` → `SBD01_SBDMBA----------------QUAL--------`.

### 3.2 Subtitle tokens

| Token | Resolve |
|-------|---------|
| `{Event}` | Localized event name |
| `{Phase}` | Localized phase name |
| `{Location}` | Localized location name |

### 3.3 Matching rules

1. Parse CSV; skip header.
2. Drop rows where `Enabled` ≠ `TRUE` (case-insensitive).
3. For each unit, walk remaining rows **in order**; first match wins.
4. A cell matches if it is `*` **or** equals the unit field **or** (for Phase/Event/Unit) the rule value is a prefix of the unit value when the rule ends with `-` (e.g. `FNL-` matches `FNL-000100`).
5. If no row matches → unit is ungrouped.
6. If matched row has empty `GroupId` → unit is ungrouped (explicit opt-out).

More specific rules MUST appear before general ones.

### 3.4 Example (MiCo winter)

```csv
Discipline,Gender,Event,Phase,Unit,Enabled,GroupId,GroupSubTitle,GroupType
BOB,*,*,TRNO,*,TRUE,{Session}_{PhaseRSC},{Phase},phase
LUG,*,*,TRNO,*,TRUE,{Session}_{PhaseRSC},{Phase},phase
SBD,*,*,QUAL,*,TRUE,{Session}_{PhaseRSC},{Phase},phase
SBD,*,*,FNL-,*,TRUE,{Session}_{PhaseRSC},{Phase},phase
```

Baseline LA28 packs: `docs/grouping/olympic-grouping-rules.csv`, `docs/grouping/para-grouping-rules.csv`.

---

## 4. Algorithm (implement from scratch)

Run this when building the schedule projection (HTTP + Redis/SSE), after units are loaded and localized.

```
inputs:
  units[]          // schedule items for competition (or for one day)
  rules[]          // enabled CSV rows, in file order

function applyGrouping(units, rules):
  // Pass 1 — assign groupId + remember matched rule per unit
  for unit in units:
    unit.groupId = null
    rule = firstMatch(rules, unit)
    if rule is null OR rule.GroupId is blank:
      continue
    if unit.sessionCode is blank:
      continue                    // unreliable; skip grouping
    resolvedId = expandTokens(rule.GroupId, unit)
    unit.groupId = resolvedId
    unit._matchedRule = rule     // internal only

  // Pass 2 — build groups map keyed by groupId
  groupsById = map()
  for unit in units where unit.groupId != null:
    g = groupsById.getOrCreate(unit.groupId)
    g.id = unit.groupId
    g.type = unit._matchedRule.GroupType
    g.memberUnits.add(unit)

  // Pass 3 — compute aggregate fields
  for g in groupsById.values():
    members = g.memberUnits sorted by startDate ascending
    g.startDate   = members[0].startDate
    g.title       = members[0].disciplineName   // ALWAYS discipline name
    g.subTitle    = resolveSubTitle(g, members)
    g.unitsCount  = members.length
    g.isLive      = any(m.liveFlag == true OR m.scheduleStatus in LIVE_STATUSES)
    g.hasMedals   = any(m.medalFlag indicates medal)
    g.hasWarnings = any(m has delay/postpone/interrupt/cancel warning — product rule)
    // strip memberUnits from public JSON

  // Pass 4 — only emit groups that have unitsCount >= 2
  // (optional but recommended: a singleton is not a UI group)
  groups = filter(groupsById.values(), unitsCount >= 2)
  // clear groupId on units whose group was dropped as singleton
  for unit in units:
    if unit.groupId not in groups.ids:
      unit.groupId = null

  return { groups, units }
```

### 4.1 Subtitle resolution

```
function resolveSubTitle(group, members):
  rule = members[0]._matchedRule
  if group.type == "discipline":
    // Special case from Grouping Confluence:
    // ignore {Phase}/{Event} template; concatenate DISTINCT event names
    return joinDistinct(members.map(m => m.eventName), ", ")
  else:
    return expandTokens(rule.GroupSubTitle, members[0])
    // If members disagree on subtitle source, prefer earliest unit's value
```

### 4.2 Hard constraints

| Constraint | Rule |
|------------|------|
| Session required | Empty `sessionCode` → do not group that unit |
| Same day only | Do not merge units across competition days into one group. Prefer scoping the algorithm per day, or include day in the internal key |
| Title | Always discipline display name — never from CSV |
| Config hot-reload | New CSV applies on next projection rebuild without process restart |

### 4.3 Why the example ids look like that

| Example `groups[].id` | Rule behind it |
|-----------------------|----------------|
| `SBD01_SBDMBA----------------QUAL--------` | `{Session}_{PhaseRSC}` for SBD QUAL |
| `LUGTC_LUGWSINGLES-----------TRNO--------` | `{Session}_{PhaseRSC}` for LUG TRNO |

Same session + same phase RSC ⇒ same group ⇒ multiple training/qual heats collapse under one card.

---

## 5. Group object schema

| Field | Type | How to compute |
|-------|------|----------------|
| `id` | string | Expanded `GroupId` template |
| `title` | string | Discipline name of members |
| `subTitle` | string | See §4.1 |
| `type` | string | `GroupType` from matched rule (`phase`, `discipline`, `event`, `location`) |
| `startDate` | datetime | Earliest member `startDate` |
| `unitsCount` | int | Number of members |
| `isLive` | bool | Any member live / in-progress |
| `hasMedals` | bool | Any member is a medal unit |
| `hasWarnings` | bool | Any member in a “warning” schedule status (delayed, postponed, interrupted, cancelled, … — align with FE badge rules) |

### Unit field

| Field | Type | Notes |
|-------|------|-------|
| `groupId` | string \| null | Same as `groups[].id`; absent/null when not grouped |

---

## 6. Persistence & rebuild

1. Store CSV (or parsed rules) per `competitionCode` (+ `feedFlag` if applicable).
2. On `POST /management/api/rules`: validate header, parse, persist, trigger projection rebuild.
3. On ODF-driven schedule changes (`DT_SCHEDULE`, `DT_SCHEDULE_UPDATE`, `DT_RESULT`, …): rebuild schedule projection **including** grouping pass.
4. SSE consumers receive updated `groups` + unit `groupId` together with unit patches (or full snapshot — match existing Schedule SSE strategy).

---

## 7. Requirements (OpenSpec)

### Requirement: Hot-configurable rules

The system SHALL accept a full CSV rule replacement via management POST and apply it without redeploy.

#### Scenario: Upload succeeds
- **WHEN** client POSTs a valid CSV with the required header
- **THEN** response is `204` and subsequent schedule responses use the new rules

### Requirement: First-match rule engine

The system SHALL match units to rules in CSV order using Discipline/Gender/Event/Phase/Unit with `*` and prefix (`…-`) semantics.

#### Scenario: Override before catch-all
- **GIVEN** a specific `FNL-` row above a `*` phase row for the same discipline
- **WHEN** a final unit is evaluated
- **THEN** the `FNL-` row wins

### Requirement: Response contract

Schedule responses SHALL expose top-level `groups[]` and per-unit `groupId` as specified in §2.1 and §5.

#### Scenario: Grouped units share id
- **WHEN** three SBD QUAL units share session `SBD01` and the same phase RSC
- **THEN** each has the same `groupId`
- **AND** exactly one `groups[]` entry exists with that `id` and `unitsCount` = 3

#### Scenario: Ungrouped unit
- **WHEN** no rule matches or `GroupId` is empty
- **THEN** the unit has no `groupId` (or null/empty)
- **AND** it does not appear in any group’s count

### Requirement: Aggregate fields

For each group the system SHALL set `title`, `subTitle`, `type`, `startDate`, `unitsCount`, `isLive`, `hasMedals`, `hasWarnings` per §4–§5.

#### Scenario: Discipline type subtitle
- **WHEN** `GroupType` is `discipline`
- **THEN** `subTitle` is the comma-separated distinct event names of members

#### Scenario: Phase type subtitle
- **WHEN** `GroupType` is `phase` and `GroupSubTitle` is `{Phase}`
- **THEN** `subTitle` is the phase name of the earliest member (e.g. “Women's Singles Official Training”)

### Requirement: Session and day safety

The system SHALL NOT group units with empty `sessionCode` and SHALL NOT form a single group from units on different competition days.

---

## 8. Non-goals

- FE expand/collapse, live-under-header promotion, ads counting (Daily Schedule UX)
- Nesting full unit objects inside `groups[]` (join by id instead)
- Cross-day session merges

---

## 9. Implementation checklist

1. [ ] Persist rules table / blob + management POST
2. [ ] Token expander (`{Session}`, `{PhaseRSC}`, …)
3. [ ] Rule matcher (order, `*`, prefix)
4. [ ] Grouping pass in schedule projection builder
5. [ ] Emit `groups` + `groupId` on public schedule / day endpoints + SSE
6. [ ] Load baseline CSV for OLY/PARA in each env
7. [ ] Tests: MiCo-style LUG/SBD cases; singleton drop; empty session; discipline subtitle concat
