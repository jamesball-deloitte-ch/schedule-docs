# DRES-32642 — WMR Schedule TRI card variant
# Freeze: ownScenarios/TRI/01_Schedule_Tile_Mixed_Day · LogicalDate 2026-09-09
# FE map: docs/TRI/schedule-tile-fe-score.md

Feature: TRI schedule tiles — before / live / medallists / country filter
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the TRI messages in ownScenarios/TRI/01_Schedule_Tile_Mixed_Day have been ingested in filename order
    And no country filter is applied unless stated

  # --- BEFORE ---

  Scenario: Before — no extra results information on the card
    Given only messages up to 2026-09-09-080022000 have been ingested
    And now is 2026-09-09T08:00:22+02:00
    When the client requests schedulesPerDay/2026-09-09 for TRI
    Then the listed competition tiles are SCHEDULED:
      | TRIWOLYMPIC-----------FNL-000100-- |
      | TRIMOLYMPIC-----------FNL-000100-- |
      | TRIXTEAM4-------------FNL-000100-- |
    And each tile shows event name, start time, venue and medal marker
    And the schedule card results section is empty
    And the card does not show athlete names, team names, medallists, IRM or race times
    And liveFlag is false on every tile
    And DRAW / MEET units are not listed
    And Victory Ceremony units follow WMR hide rules

  # --- DURING (live) ---

  Scenario: During — Women's Individual marked live only
    Given now is 2026-09-09T12:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for TRI
    Then Women's Individual TRIWOLYMPIC-----------FNL-000100-- is RUNNING with liveFlag true
    And the Women's tile is visually highlighted as live
    And the Women's card results section is empty
    And the Women's card does not show live race times, ranks, medallists or IRM

  # --- AFTER (medals) ---

  Scenario: After — Men's Individual shows athlete medallists
    Given now is 2026-09-09T12:00:00+02:00
    Then Men's Individual TRIMOLYMPIC-----------FNL-000100-- is FINISHED
    And liveFlag is false
    And the card shows medallist rows for athletes only:
      | organisation | display name   | medal  |
      | AUT          | Alois Knabl    | GOLD   |
      | AZE          | Rostislav Pevtsov | SILVER |
      | BAR          | Matthew Wright | BRONZE |
    And each medallist row shows NOC flag and/or code plus athlete name and medal icon
    And the card does not show the full start list or race times
    And without a country filter the card does not show IRM badges

  Scenario: After — Mixed Relay shows team medallists
    Given now is 2026-09-09T12:00:00+02:00
    Then Mixed Relay TRIXTEAM4-------------FNL-000100-- is FINISHED
    And the card shows medallist rows for teams only:
      | organisation | display name | medal  |
      | ITA          | Italy        | GOLD   |
      | GER          | Germany      | SILVER |
      | SUI          | Switzerland  | BRONZE |
    And each medallist row shows NOC flag and/or code plus team name and medal icon
    And the card does not show individual leg athletes as separate medallist rows
    And without a country filter the card does not show IRM badges

  Scenario: Full ingest mixed freeze overview
    Given now is 2026-09-09T12:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for TRI
    Then the listed tiles are:
      | TRIWOLYMPIC-----------FNL-000100-- | RUNNING  |
      | TRIMOLYMPIC-----------FNL-000100-- | FINISHED |
      | TRIXTEAM4-------------FNL-000100-- | FINISHED |
    And no tile has a groupId
    And no tile shows a race score on the schedule card
    And medalFlag is 1 on all three competition finals

  # --- COUNTRY FILTER ---

  Scenario: Country filter — individual event shows athletes from that NOC
    Given now is 2026-09-09T12:00:00+02:00
    And the API competitors arrays still contain the full unit start lists
    When the user filters the schedule by organisation AUT
    Then Men's Individual remains listed because at least one competitor has organisation AUT
    And the Men's card results block shows only AUT athletes from competitors[]
    And Women's Individual remains listed if any woman has organisation AUT
    And those Women's rows show athlete names not team names

  Scenario: Country filter — Mixed Relay shows teams from that NOC
    Given now is 2026-09-09T12:00:00+02:00
    When the user filters the schedule by organisation AUT
    Then Mixed Relay remains listed because team TRIXTEAM4-------------AUT01 has organisation AUT
    And the Mixed Relay card results block shows the AUT team row with the team display name
    And the Mixed Relay card does not list athletes from other NOCs

  Scenario: Country filter — IRM only on competitors from the filtered NOC
    Given now is 2026-09-09T12:00:00+02:00
    And Men's Official result includes IRM DNF for Kaindl AUT (9438537)
    And Men's Official result includes IRM DNF for Hauser AUS (9436491)
    When no country filter is applied
    Then the Men's card does not show IRM badges on any row
    When the user filters by organisation AUT
    Then the Men's card shows IRM DNF on the AUT athlete row for Kaindl
    And the Men's card does not show the AUS athlete Hauser
    And therefore no AUS IRM is visible on the card

  Scenario: Country filter — IRM on Mixed Relay team from filtered NOC
    Given now is 2026-09-09T12:00:00+02:00
    And Mixed Relay Official result includes IRM DSQ for FRA team
    When the user filters by organisation FRA
    Then the Mixed Relay card shows the FRA team row with IRM DSQ
    When no country filter is applied
    Then the Mixed Relay card shows only team medallists and no IRM badges

  # --- REDIRECTS ---

  Scenario: Card click redirects use unit RSC
    Given now is 2026-09-09T12:00:00+02:00
    Then clicking Women's Individual opens unit results for TRIWOLYMPIC-----------FNL-000100--
    And clicking Men's Individual opens unit results for TRIMOLYMPIC-----------FNL-000100--
    And clicking Mixed Relay opens unit results for TRIXTEAM4-------------FNL-000100--
    And the href does not change between before, during and after
