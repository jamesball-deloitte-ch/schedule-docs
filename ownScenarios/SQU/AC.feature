Feature: SQU schedule tiles — 01 mixed / edge day
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the SQU messages in ownScenarios/SQU/01_Schedule_Tile_Mixed_Day have been ingested in filename order

  Scenario: After morning schedule only — no opponents
    Given only messages up to 2026-09-09-080001000 have been ingested
    And now is 2026-09-09T08:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for SQU
    Then the same ten unit RSCs are listed as SCHEDULED
    And every tile has empty competitors and empty placeholderOpponents
    And the tile shows event and phase meta only
    When the user clicks any listed tile
    Then the href is the unit-results URL for that tile RSC

  Scenario: After full ingest — default daily list
    Given now is 2026-09-09T14:30:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for SQU
    Then every listed item is an event unit RSC
    And no item is a phase RSC (all SQU phases are Schedule = N)
    And the listed tiles include:
      | SQUWSINGLES-----------FNL-000200-- | FINISHED      |
      | SQUWSINGLES-----------FNL-000100-- | FINISHED      |
      | SQUMSINGLES-----------8FNL000100-- | FINISHED      |
      | SQUMSINGLES-----------8FNL000200-- | FINISHED      |
      | SQUMSINGLES-----------QFNL000100-- | FINISHED      |
      | SQUMSINGLES-----------QFNL000200-- | RUNNING       |
      | SQUMSINGLES-----------QFNL000300-- | GETTING_READY |
      | SQUMSINGLES-----------QFNL000400-- | SCHEDULED     |
      | SQUMSINGLES-----------SFNL000100-- | SCHEDULED     |
      | SQUMSINGLES-----------SFNL000200-- | SCHEDULED     |

  Scenario: Women's Singles event already has medallists
    Given now is 2026-09-09T14:30:00+02:00
    Then Women's Singles Bronze is FINISHED with medalFlag 3
    And Women's Singles Gold is FINISHED with medalFlag 1
    And the Women's Singles event exposes medallists Allinckx SUI gold and Sramkova CZE bronze
    And Bronze and Gold are not grouped together

  Scenario: Live men's quarterfinal shows games score
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's QF2 QFNL000200 is RUNNING with liveFlag true
    And the tile shows Iqbal 0 and Byrtus 2
    And the tile has no liveCurrentProgress
    And there is no Scheduled badge

  Scenario: Finished men's QF1 shows games won
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's QF1 QFNL000100 is FINISHED
    And the tile shows Omlor 3 and Shcherbakov 2
    And Omlor has winLoseTie W

  Scenario: Walkover and retirement use row IRM
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's R16 8FNL000100 is FINISHED with walkover IRM W/O
    And Men's R16 8FNL000200 is FINISHED with Zhou IRM RET
    And Shcherbakov is shown as winner with games 3

  Scenario: Single W/O or RET — FE shows IRM on the row only
    Given now is 2026-09-09T14:30:00+02:00
    And Men's R16 8FNL000100 has invalidResultMark W/O
    And Men's R16 8FNL000200 has Zhou invalidResultMark RET
    When the schedule card renders
    Then each affected competitor row shows invalidResultMark (W/O or RET) next to the score
    And the card has no unit-level resultDecision label

  Scenario: Men's QF4 is scheduled with named opponents
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's QF4 QFNL000400 is SCHEDULED
    And the tile shows Zaman vs Zhu
    And the tile has no liveFlag and no score

  Scenario: SF1 has known player plus TBD placeholder from unfinished QF2
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's SF1 lists Omlor against a placeholderOpponent
    And the placeholder name is TBD
    And the tile does not show Winner n or other composed bracket text

  Scenario: SF2 both opponents unknown — no placeholder rows
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's SF2 has empty competitors and empty placeholderOpponents
    And the tile shows event and phase meta only

  Scenario: Getting Ready has no live score
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's QF3 is GETTING_READY
    And the tile shows Rodriguez vs Farkas
    And the tile has no liveFlag and no liveCurrentProgress

  Scenario: Card click always goes to unit results
    Given now is 2026-09-09T14:30:00+02:00
    When the user clicks any listed tile
    Then the href is the unit-results URL for that tile RSC
    And the href does not change between before, during and after


Feature: SQU schedule tiles — 02 women finals done, men mid-QF
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the SQU messages in ownScenarios/SQU/02_Schedule_Tile_Women_Finals_Men_QF have been ingested in filename order

  Scenario: After morning schedule only — no opponents
    Given only messages up to 2026-09-09-080001000 have been ingested
    And now is 2026-09-09T08:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for SQU
    Then the same eleven unit RSCs are listed as SCHEDULED
    And every tile has empty competitors and empty placeholderOpponents

  Scenario: After full ingest — women finished, men mid QF
    Given now is 2026-09-09T14:30:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for SQU
    Then every listed item is an event unit RSC
    And no item is a phase RSC
    And the listed tiles include:
      | SQUWSINGLES-----------SFNL000100-- | FINISHED      |
      | SQUWSINGLES-----------SFNL000200-- | FINISHED      |
      | SQUWSINGLES-----------FNL-000200-- | FINISHED      |
      | SQUWSINGLES-----------FNL-000100-- | FINISHED      |
      | SQUMSINGLES-----------8FNL000500-- | FINISHED      |
      | SQUMSINGLES-----------QFNL000100-- | FINISHED      |
      | SQUMSINGLES-----------QFNL000200-- | RUNNING       |
      | SQUMSINGLES-----------QFNL000300-- | GETTING_READY |
      | SQUMSINGLES-----------QFNL000400-- | SCHEDULED     |
      | SQUMSINGLES-----------SFNL000100-- | SCHEDULED     |
      | SQUMSINGLES-----------SFNL000200-- | SCHEDULED     |

  Scenario: Women's Singles semis and finals with full podium
    Given now is 2026-09-09T14:30:00+02:00
    Then Women's SF1 shows Lamb 0 and Watanabe 3
    And Women's SF2 shows Otrzasek 3 and Lincou 0
    And Women's Bronze shows Lamb 0 and Lincou 3 with medalFlag 3
    And Women's Gold shows Watanabe 0 and Otrzasek 3 with medalFlag 1
    And the Women's Singles event exposes medallists Otrzasek POL gold, Watanabe JPN silver, Lincou FRA bronze
    And Bronze and Gold are not grouped together

  Scenario: Live men's QF2 shows games won
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's QF2 QFNL000200 is RUNNING with liveFlag true
    And the tile shows Nasser 1 and Wilhelmi 1
    And the tile has no liveCurrentProgress

  Scenario: One IRM retirement on men's R16
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's R16 8FNL000500 is FINISHED
    And Rodriguez has invalidResultMark RET
    And Lau is shown as winner with games 3

  Scenario: Single RET — FE shows IRM on the row only
    Given now is 2026-09-09T14:30:00+02:00
    And Men's R16 8FNL000500 has Rodriguez invalidResultMark RET
    When the schedule card renders
    Then Rodriguez's row shows invalidResultMark RET next to the score
    And the card has no unit-level resultDecision label
    And Lau's row has no IRM

  Scenario: Finished men's QF1 shows games won
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's QF1 QFNL000100 is FINISHED
    And the tile shows Adegoke 3 and Zhou 0
    And Adegoke has winLoseTie W

  Scenario: SF1 mixed known plus TBD placeholder from unfinished QF2
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's SF1 lists Adegoke against a placeholderOpponent
    And the placeholder name is TBD
    And the tile does not show Winner n or other composed bracket text

  Scenario: SF2 both opponents unknown — no placeholder rows
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's SF2 has empty competitors and empty placeholderOpponents
    And the tile shows event and phase meta only

  Scenario: Card click always goes to unit results
    Given now is 2026-09-09T14:30:00+02:00
    When the user clicks any listed tile
    Then the href is the unit-results URL for that tile RSC
