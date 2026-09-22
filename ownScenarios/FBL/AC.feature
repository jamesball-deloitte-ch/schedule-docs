Feature: FBL schedule tiles mid-group freeze
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the FBL messages in own_scenarios/FBL/01_Schedule_Tile_Mid_Group have been ingested in filename order
    And now is 2026-09-09T13:00:00+02:00

  Scenario: Today's list is the six men's group matches on 2026-09-09
    When the client requests schedulesPerDay/2026-09-09 for FBL
    Then the listed tiles are:
      | FBLMTEAM11------------GPC-000300-- | INTERRUPTED | Mali vs Egypt |
      | FBLMTEAM11------------GPB-000300-- | RUNNING     | Argentina vs Iraq |
      | FBLMTEAM11------------GPA-000300-- | RUNNING     | France vs Guinea |
      | FBLMTEAM11------------GPA-000400-- | SCHEDULED   | New Zealand vs Jamaica |
      | FBLMTEAM11------------GPC-000400-- | SCHEDULED   | Dominican Republic vs Spain |
      | FBLMTEAM11------------GPB-000400-- | SCHEDULED   | Japan vs Morocco |
    And no tile shows a Scheduled badge
    And women's matches from 2026-09-08 are not on this day list

  Scenario: Live matches show period and score
    Then France vs Guinea is RUNNING with liveFlag true
    And the tile score is 1-0
    And liveCurrentProgress is H1 from Clock Period H1
    And Argentina vs Iraq is RUNNING with liveFlag true
    And the tile score is 2-1
    And liveCurrentProgress is H2

  Scenario: Interrupted match keeps score and HT
    Then Mali vs Egypt is INTERRUPTED
    And the tile score is 0-0
    And liveCurrentProgress is HT
    And the Clock is not running

  Scenario: HideStartDate uses startText
    Then New Zealand vs Jamaica is SCHEDULED
    And hideStartDate is true
    And the time slot shows TBC not 18:00
    And Dominican Republic vs Spain still shows 18:00

  Scenario: Earlier finished matches keep resultDecision
    When the client opens a day that includes the 2026-09-06 men's group
    Then France vs Jamaica GPA-000100 is FINISHED 2-1 with no resultDecision
    And Argentina vs Morocco GPB-000100 is FINISHED 2-1 with resultDecision AET
    And Mali vs Spain GPC-000100 is FINISHED 1-1 with resultDecision PSO and PSO tallies 4-5
    And Guinea vs New Zealand GPA-000200 is FINISHED 3-0 with resultDecision FORFEIT

  Scenario: Later knockout tiles keep TBD placeholders
    When the client opens 2026-09-14
    Then Women's Quarter-final tiles are SCHEDULED
    And opponents are placeholder TBD
    And there is no Scheduled badge

  Scenario: Card click always goes to unit results
    When the user clicks any listed tile
    Then the href is the unit-results URL for that RSC
    And the href does not change between before, during and after
    And FBL has no Schedule RSC override on these group matches
