Feature: TTE medals for all events
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the TTE messages in own_scenarios/TTE/01_Medals_All_Events have been ingested in filename order
    And now is 2026-09-09T16:00:06+02:00

  Scenario: Every event has official medallists
    Then DT_MEDALLISTS exists for each of:
      | TTEXDOUBLES----------------------- |
      | TTEMDOUBLES----------------------- |
      | TTEWDOUBLES----------------------- |
      | TTEMSINGLES----------------------- |
      | TTEWSINGLES----------------------- |
      | TTEXTEAM-------------------------- |
    And each message has ResultStatus OFFICIAL
    And each message has ME_GOLD, ME_SILVER and ME_BRONZE

  Scenario: Singles medallists are athletes from raw PARTIC
    Then Men's Singles gold is Wang Chuqin CHN (9440007)
    And Men's Singles silver is Lebrun Felix FRA (9449877)
    And Men's Singles bronze is Harimoto Tomokazu JPN (9441399)
    And Women's Singles gold is Sun Yingsha CHN (9442013)
    And Women's Singles silver is Hayata Hina JPN (9441300)
    And Women's Singles bronze is Shin Yubin KOR (9446335)

  Scenario: Doubles and team medallists are teams from raw ENTRIES
    Then Mixed Doubles gold is TTEXDOUBLES-----------CHN01 with Wang Chuqin and Sun Yingsha
    And Men's Doubles gold is TTEMDOUBLES-----------CHN01 with Fan Zhendong and Ma Long
    And Women's Doubles gold is TTEWDOUBLES-----------CHN01 with Chen Meng and Sun Yingsha
    And Mixed Team gold is TTEXTEAM--------------CHN01
    And Mixed Team silver is TTEXTEAM--------------JPN01
    And Mixed Team bronze is TTEXTEAM--------------KOR01

  Scenario: Discipline medal standings match the six podiums
    When DT_MEDALS for TTE is read
    Then TotalEvents is 6 and FinishedEvents is 6
    And LastEvent is TTEXTEAM--------------------------
    And MedalSummary TOT is Gold 6 Silver 6 Bronze 6
    And CHN ranks 1 with 6 gold
    And JPN ranks 2 with 4 silver and 1 bronze
    And KOR has 4 bronze and RankTotal 3
