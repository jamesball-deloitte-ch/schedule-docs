Feature: CKT schedule tiles — multi-day team freeze
  Background:
    Given competition OG2028-ITL
    And the CKT messages in own_scenarios/CKT/01_Schedule_Tile_Mixed_Days have been ingested in filename order

  Scenario: Team bootstrap precedes schedule
    Given only messages up to 2026-09-09-080003000 have been ingested
    Then DT_PARTIC_TEAMS_UPDATE has loaded team Type=T identities
    And DT_ENTRIES for CKTMT20 and CKTWT20 define team compositions
    And no schedule tiles are available yet

  Scenario: Morning schedule — all competition units before
    Given only messages up to 2026-09-09-080004000 have been ingested
    And now is 2026-09-09T08:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for CKT
    Then today's competition tiles are SCHEDULED:
      | CKTWT20---------------GP1A000200-- |
      | CKTMT20---------------FNL-000200-- |
      | CKTMT20---------------FNL-000100-- |
    And no tile shows a Scheduled badge
    And no tile has liveFlag or medallists
    And no tile has a groupId

  Scenario: Day lists span four LogicalDates
    Given now is 2026-09-09T15:15:00+02:00
    When the client requests schedulesPerDay for each day
    Then 2026-09-06 lists Women's GP1A000100 and GP1B000100 as FINISHED
    And 2026-09-07 lists Men's GP2-000100..000300 as FINISHED
    And 2026-09-08 lists Men's GP2-000400..000600 as FINISHED
    And 2026-09-09 lists Women GP1A000200, Men's Bronze, Men's Gold

  Scenario: Finished women group shows cricket score and finalResultDescription
    Given now is 2026-09-09T15:15:00+02:00
    When the client opens schedulesPerDay/2026-09-06
    Then CKTWT20 GP1A000100 is FINISHED Australia vs India
    And scores are runs/wickets form
    And FINAL_RESULT is WON_WKT with SCORE 9
    And finalResultDescription interpolates India beat Australia by 9 wickets
    And competitors are Type=T from PARTIC_TEAMS / ENTRIES

  Scenario: Tied match keeps Super Over period scores
    Given now is 2026-09-09T15:15:00+02:00
    When the client opens schedulesPerDay/2026-09-08
    Then CKTMT20 GP2-000600 is FINISHED Pakistan vs India
    And FINAL_RESULT is MATCH TIED
    And Super Over period scores are present on the result

  Scenario: Mid-morning — Women's Super Over live
    Given only messages up to 2026-09-09-090001000 have been ingested
    And now is 2026-09-09T09:00:01+02:00
    Then CKTWT20 GP1A000200 is RUNNING with liveFlag true
    And liveCurrentProgress is SO1IN2
    And tile scores are runs/wickets
    And DT_MEDALLISTS has not been ingested yet

  Scenario: Mid-afternoon — Gold live with innings progress
    Given only messages up to 2026-09-09-143001000 have been ingested
    And now is 2026-09-09T14:30:01+02:00
    Then CKTMT20 FNL-000100 is RUNNING with liveFlag true
    And liveCurrentProgress is IN2
    And New Zealand score is 164/9 and South Africa is 19/0
    And medalFlag is 1
    And DT_MEDALS has not been ingested yet

  Scenario: After full ingest — Gold NO RESULT and medals order
    Given now is 2026-09-09T15:15:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for CKT
    Then the listed competition tiles are:
      | CKTWT20---------------GP1A000200-- | RUNNING  | India vs Barbados Super Over |
      | CKTMT20---------------FNL-000200-- | FINISHED | Australia vs Pakistan bronze |
      | CKTMT20---------------FNL-000100-- | FINISHED | New Zealand vs South Africa gold |
    And Gold FINAL_RESULT is NO RESULT
    And finalResultDescription reflects No Result
    And DT_MEDALLISTS was ingested before DT_MEDALS
    And medallists are NZL gold, RSA silver, AUS bronze
    And Victory Ceremony is not listed on WMR:
      | CKTMT20---------------VICTMEDAL--- |
    And UNSCHEDULED meetings are not listed:
      | CKTMT20---------------MEET000100-- |
      | CKTWT20---------------MEET000100-- |

  Scenario: CC Schedule flag is Y not S
    Given now is 2026-09-09T15:15:00+02:00
    Then every listed competition unit is CC Schedule=Y
    And CKT has zero Schedule=S units in CC @Unit

  Scenario: Card click always goes to unit results
    Given now is 2026-09-09T15:15:00+02:00
    When the user clicks any listed competition tile
    Then the href is the unit-results URL for that RSC
    And the href does not change between before, during and after
    And WMR uses the compact CKT path shape for group / final units
