# Change: Baseline Paris schedule grouping for LA28

## Why

LA28 Schedule needs runtime grouping rules. MiCo already has the CSV + management API contract ([Grouping](https://dgplatform.atlassian.net/wiki/spaces/M/pages/1685717676/Grouping)). Product captured Paris OLY/PARA decisions as a draft baseline ([Grouping for schedule](https://dgplatform.atlassian.net/wiki/spaces/WLCR/pages/3242590237/Grouping+for+schedule)) marked “use as a baseline, but will need to be updated”.

This change turns that matrix into loadable CSVs and a backend OpenSpec so Schedule API / ops can apply and evolve rules without redeploys.

## What Changes

- Add Olympic and Paralympic baseline CSV rule packs under `docs/grouping/`
- Add OpenSpec capability `schedule-grouping` as a **from-scratch** backend guide: rule engine, `groups[]` + unit `groupId` contract, aggregate fields (`isLive`, `hasMedals`, `unitsCount`, …)
- Document open product actions from the Paris page (title CRs, MPN A/B, BKG GP phases, etc.)

## Impact

- **Affected specs:** `schedule-grouping` (new)
- **Affected code:** Schedule API rule engine + `schedulesGrouped` projection (behaviour already exists; this is configuration + contract clarity)
- **Consumers:** WMR Daily Schedule, CIS schedule UIs using grouped cards

## Paris → CSV mapping (Olympic)

| Disc | Paris decision | CSV approach |
|------|----------------|--------------|
| ARC | Yes\* Event (partial) | No-group `FNL-`; else `{Session}_{EventRSC}` / event |
| BDM | Yes Discipline | `{Session}` / discipline |
| BKG | Yes — GPA–GPD one group; title by Phase | All `GPA-`…`GPD-` share `{Session}` / discipline |
| BMX, BOX, CSL, CSP, CTR, FEN, ROW, SRF, TKW | Yes Phase | `{Session}_{PhaseRSC}` / phase |
| JUD | Yes Location; finals by disc | `FNL-` → `{Session}` discipline; else location |
| MPN | Yes — SF A/B separate, Final separate | `SFNL` → `{Session}_{Unit}`; `FNL-` → `{Session}`; else phase (**needs validation**) |
| SAL | Yes Discipline | `{Session}` / discipline |
| TEN | Yes Location | `{Session}_{LocationCode}` / location |
| TTE | Yes Phase — group PREL+R64+R32+R16; no QF/SF/FNL | Early rounds `{Session}` discipline; QFNL/SFNL/FNL- empty GroupId |
| WRE | Yes Location + disc for FNL | `FNL-` discipline; else location |
| ATH, BK3, BKB, BMF, CLB, CRD, DIV, EQU, FBL, GAR, GLF, GRY, GTR, HBL, HOC, MTB, OWS, RU7, SHO, SKB, SWA, SWM, TRI, VBV, VVO, WLF, WPO | No | Omitted (no rule ⇒ no group) |

## Paris → CSV mapping (Paralympic)

| Disc | Paris decision | CSV approach |
|------|----------------|--------------|
| ARC | Event; don’t group QUAL/FNL | Explicit empty GroupId for QUAL & FNL-; else event |
| BDM | Location (Disc struck through) | location |
| BOC, CSP | Event | event |
| CRD, SWM | Disc | discipline |
| JUD, WTE | Location | location |
| TKW | Disc; FNL by Event | FNL- event override; else discipline |
| TTE, WFE | Phase | phase |
| TMRY | Don’t group | Explicit empty GroupId |
| ATH, CTR, EQU, FBB, GBL, PWL, ROW, SHO, TRI, VBS, WBK, WRU | No | Omitted |

## Open points (from Paris notes — not fully solvable in CSV alone)

1. **BDM OLY** — “update the title and add all the events” (needs Story / possibly disc-type subtitle CR).
2. **BKG** — “add title by Phase, which doesn’t seem to work” while also needing one group for GPA–GPD; current pack uses `GroupType=discipline` + shared `{Session}` so Phase subtitle may not drive Daily Schedule.
3. **BOX** — consider switching from Phase to Discipline if UI is too noisy.
4. **BMX** — “NOT BEEN ABLE TO TEST”.
5. **MPN** — want “A” / “B” in semi titles; same phase must split; Unit-based GroupId is a hypothesis.
6. **WRE FNL** — “need the CR for the title of group by disc”.
7. **TTE phase codes** — pack includes `R64-`/`R32-`/`R16-`/`8FNL`; confirm against LA28 ODF phase codes.
8. **GroupType limitation** — only `discipline` affects Daily Schedule groups today; location/phase/event metadata still emitted for future FE.

## Out of Scope

- FE Grouped Unit Card UX (expand all, live promotion, a11y)
- Per-environment POST of the CSV (ops runbook)
- Final LA28 sign-off of the Paris matrix
