## ADDED Requirements

### Requirement: Baseline Olympic and Paralympic CSV packs

The project SHALL ship baseline grouping CSV packs derived from the Paris matrix in [Grouping for schedule](https://dgplatform.atlassian.net/wiki/spaces/WLCR/pages/3242590237/Grouping+for+schedule), expressed in the schema from [Grouping](https://dgplatform.atlassian.net/wiki/spaces/M/pages/1685717676/Grouping).

#### Scenario: Olympic pack covers Paris “Yes” disciplines
- **WHEN** operators load `docs/grouping/olympic-grouping-rules.csv`
- **THEN** rules SHALL exist for ARC, BDM, BKG, BMX, BOX, CSL, CSP, CTR, FEN, JUD, MPN, ROW, SAL, SRF, TEN, TKW, TTE, WRE as specified in the proposal mapping
- **AND** Paris “No” disciplines SHALL remain ungrouped by omission

#### Scenario: Paralympic pack covers Paris PARA “Yes” disciplines
- **WHEN** operators load `docs/grouping/para-grouping-rules.csv`
- **THEN** rules SHALL exist for ARC, BDM, BOC, CRD, CSP, JUD, SWM, TKW, TTE, WFE, WTE
- **AND** TMRY SHALL be explicitly ungrouped
- **AND** Paris PARA “No” disciplines SHALL remain ungrouped by omission

#### Scenario: Order preserves overrides
- **WHEN** a discipline has both a specific phase/event override and a catch-all rule (ARC FNL, JUD FNL, TTE late rounds, TKW PARA FNL, WRE FNL)
- **THEN** the override row SHALL appear earlier in the CSV than the catch-all
