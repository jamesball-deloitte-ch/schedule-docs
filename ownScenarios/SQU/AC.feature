Feature: SQU schedule tiles — one mixed-day playback
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the SQU messages in ownScenarios/SQU/01_Schedule_Tile_Mixed_Day have been ingested in filename order

  Scenario: After morning schedule only — no opponents
    Given only messages up to 2026-09-09-080001000 have been ingested
    And now is 2026-09-09T08:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for SQU
    Then the same nine unit RSCs are listed as SCHEDULED
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
      | SQUMSINGLES-----------SFNL000100-- | SCHEDULED     |
      | SQUMSINGLES-----------SFNL000200-- | SCHEDULED     |

  Scenario: Women's Singles event already has medallists
    Given now is 2026-09-09T14:30:00+02:00
    Then Women's Singles Bronze is FINISHED with medalFlag 3
    And Women's Singles Gold is FINISHED with medalFlag 1
    And the Women's Singles event exposes medallists Allinckx SUI gold and Sramkova CZE bronze
    And Bronze and Gold are not grouped together

  Scenario: Live men's quarterfinal shows games score and current game
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's QF2 QFNL000200 is RUNNING with liveFlag true
    And the tile shows Iqbal 0 and Byrtus 2
    And liveCurrentProgress is Game 3 from UI/PERIOD G3
    And there is no Scheduled badge

  Scenario: Finished men's QF1 shows games won
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's QF1 QFNL000100 is FINISHED
    And the tile shows Omlor 3 and Shcherbakov 2
    And Omlor has winLoseTie W

  Scenario: Walkover and retirement use resultDecision
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's R16 8FNL000100 is FINISHED with resultDecision W/O
    And Men's R16 8FNL000200 is FINISHED with Zhou IRM RET and resultDecision RET
    And Shcherbakov is shown as winner with games 3

  Scenario: Placeholder opponent is TBD until QF2 finishes
    Given now is 2026-09-09T14:30:00+02:00
    Then Men's SF1 lists Omlor against TBD
    And PreviousUnit points at QFNL000100 W (UnitNum 09)
    And Men's SF2 has no StartList competitors yet

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
