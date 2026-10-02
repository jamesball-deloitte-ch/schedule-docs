Feature: CRD schedule tiles — multi-schedule playback
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the CRD messages in own_scenarios/CRD/01_Schedule_Tile_Mixed_Day have been ingested in filename order

  Scenario: After morning schedule only — all before
    Given only messages up to 2026-09-09-080001000 have been ingested
    And now is 2026-09-09T08:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for CRD
    Then the listed competition tiles are all SCHEDULED:
      | CRDWTT----------------FNL-000100-- |
      | CRDMTT----------------FNL-000100-- |
      | CRDWRR----------------FNL-000100-- |
      | CRDMRR----------------FNL-000100-- |
    And no tile shows medallists or liveFlag
    And Meeting / Victory / UNSCHEDULED rows follow WMR hide rules

  Scenario: Mid-morning — Women's ITT running
    Given only messages up to 2026-09-09-090000000 have been ingested
    And now is 2026-09-09T09:00:00+02:00
    Then Women's Individual Time Trial is RUNNING with liveFlag true
    And Men's Road Race is still SCHEDULED
    And there are no medallists yet

  Scenario: Live Men's RR with DT_CURRENT before medals
    Given only messages up to 2026-09-09-110001000 have been ingested
    And now is 2026-09-09T11:00:00+02:00
    Then Women's ITT is RUNNING
    And Men's Road Race is RUNNING with liveFlag true
    And DT_CURRENT is available for Men's Road Race
    And the tile does not show a race score
    And DT_MEDALLISTS has not been ingested yet

  Scenario: After full ingest — mixed freeze
    Given now is 2026-09-09T12:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for CRD
    Then the listed tiles are:
      | CRDWTT----------------FNL-000100-- | FINISHED      |
      | CRDMTT----------------FNL-000100-- | GETTING_READY |
      | CRDWRR----------------FNL-000100-- | INTERRUPTED   |
      | CRDMRR----------------FNL-000100-- | RUNNING       |
    And no tile has a groupId
    And Meeting and Victory Ceremony units are not listed on WMR:
      | CRDGGEN---------------MEET000200-- |
      | CRDWTT----------------VICTMEDAL--- |
    And UNSCHEDULED familiarisation is not listed:
      | CRDGGEN---------------MEET000500-- |

  Scenario: After entries and start lists — full competitors for country filter
    Given only messages up to 2026-09-09-080017000 have been ingested
    And now is 2026-09-09T08:00:17+02:00
    When the client requests schedulesPerDay/2026-09-09 for CRD
    Then each listed competition tile has a non-empty competitors array from that unit DT_RESULT START_LIST
      | CRDWTT----------------FNL-000100-- | 35 |
      | CRDMTT----------------FNL-000100-- | 35 |
      | CRDWRR----------------FNL-000100-- | 95 |
      | CRDMRR----------------FNL-000100-- | 90 |
    And DT_ENTRIES has been ingested for the four event RSCs
    And competitors include organisation for every athlete
    And filtering by organisation POL returns at least Women's ITT when Lach is entered
    And the schedule card UI still does not render the full peloton

  Scenario: Finished Women's ITT shows medallists and medals standings
    Given now is 2026-09-09T12:00:00+02:00
    Then Women's Individual Time Trial is FINISHED
    And competitors still contains the full start list not only three athletes
    And three competitors have result.medal for Zabelinskaya UZB, Lach POL, van de Velde BEL
    And the tile UI shows those three medallists
    And DT_MEDALS has been ingested for CRD
    And the tile does not show a race score
    And medalFlag is 1

  Scenario: Women's Road Race interrupted
    Given now is 2026-09-09T12:00:00+02:00
    Then Women's Road Race is INTERRUPTED
    And liveFlag is false
    And the tile does not show a race score

  Scenario: Men's ITT before and Men's RR still live
    Given now is 2026-09-09T12:00:00+02:00
    Then Men's Individual Time Trial is GETTING_READY with medal marker and no medallists
    And Men's Road Race is RUNNING with liveFlag true
    And DT_CURRENT remains available
    And neither tile shows a race score or resultDecision

  Scenario: Card click always goes to that unit results
    Given now is 2026-09-09T12:00:00+02:00
    When the user clicks any listed competition tile
    Then the href is the unit-results URL for that tile RSC
    And the href does not change between before, during and after
