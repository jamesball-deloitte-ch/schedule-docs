# Schedule grouping

**Start here for backend (from scratch):** [`openspec/specs/schedule-grouping/spec.md`](../../openspec/specs/schedule-grouping/spec.md) — algorithm, `groups[]` + `groupId` contract, CSV engine.

## Sources

| Document | Role |
|----------|------|
| [Grouping](https://dgplatform.atlassian.net/wiki/spaces/M/pages/1685717676/Grouping) | CSV schema, tokens, management API |
| [Schedule - daily schedule](https://dgplatform.atlassian.net/wiki/spaces/M/pages/2586509406/Schedule+-+daily+schedule) | Historical `groups` / `groupId` response |
| [Grouping for schedule](https://dgplatform.atlassian.net/wiki/spaces/WLCR/pages/3242590237/Grouping+for+schedule) | Paris OLY/PARA discipline matrix (baseline) |
| [Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule) | LA28 unit fields (`sessionCode`, RSC, location) |

## Deliverables

| File | Purpose |
|------|---------|
| [`olympic-grouping-rules.csv`](./olympic-grouping-rules.csv) | OLY baseline rules (Paris → LA28) |
| [`para-grouping-rules.csv`](./para-grouping-rules.csv) | PARA baseline rules |
| [`squ-sim-grouping-rules.csv`](./squ-sim-grouping-rules.csv) | **Test only** — SQU phase groups (`{PhaseRSC}`, across sessions) for `ownScenarios/SQU` (not OLY baseline; Paris: no SQU grouping). `POST` is a full replace — this file groups SQU only. |
| [`../../openspec/specs/schedule-grouping/spec.md`](../../openspec/specs/schedule-grouping/spec.md) | Greenfield backend OpenSpec |
| [`../../openspec/changes/baseline-paris-schedule-grouping/proposal.md`](../../openspec/changes/baseline-paris-schedule-grouping/proposal.md) | Paris matrix mapping + open points |

## How to apply rules

`POST` raw CSV (with header) to `/{competition}/schedules/management/api/rules` — see [Grouping](https://dgplatform.atlassian.net/wiki/spaces/M/pages/1685717676/Grouping) for env URLs. Expect `204`.

First-match; put specific rows before wildcards.
