# Tasks: Baseline Paris schedule grouping

## 1. Spec & packs

- [x] 1.1 Capture CSV schema + constraints from Grouping Confluence into OpenSpec
- [x] 1.2 Translate Paris OLY matrix → `docs/grouping/olympic-grouping-rules.csv`
- [x] 1.3 Translate Paris PARA matrix → `docs/grouping/para-grouping-rules.csv`
- [x] 1.4 Document open product actions (MPN A/B, BKG title, WRE CR, TTE codes)

## 2. Backend validation (follow-up)

- [ ] 2.1 Confirm phase prefix matching (`FNL-`, `R64-`, `GPA-`, …) against Schedule API matcher
- [ ] 2.2 Confirm `GroupType` behaviour for Daily Schedule vs metadata-only types
- [ ] 2.3 Validate MPN SF A/B split via `{Session}_{Unit}` on real feed
- [ ] 2.4 POST packs to DEV and spot-check `schedulesGrouped` for ARC, TTE, JUD, BKG

## 3. Product follow-up

- [ ] 3.1 Resolve open notes on BDM title, BOX disc vs phase, BMX test, WRE FNL title CR
- [ ] 3.2 Update Paris matrix page after LA28 decisions; refresh CSVs
