/* ────────────────────────────────────────────────────────────────────────────────
   Produce a single, consolidated table that shows the “top-five” records in each
   of four requested categories.

   Columns returned:
     • Category           – name of the ranking category
     • Date               – game date (or 'N/A' for venues)
     • Matchup_or_Venue   – readable description of the game or arena
     • Key_Metric         – the value being ranked on
   ────────────────────────────────────────────────────────────────────────────────*/

WITH
-- 1) five largest arenas
top_venues AS (
  SELECT
    'Top Venues'                                         AS Category ,
    'N/A'                                                AS Date ,
    CONCAT(venue_name,' (',venue_city,', ',venue_state,')')
                                                         AS Matchup_or_Venue ,
    venue_capacity                                       AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  ORDER BY venue_capacity DESC
  LIMIT 5
),

-- 2) biggest National-Championship winning margins since 2016
champ_margins AS (
  SELECT
    'Biggest Championship Margins'                       AS Category ,
    CAST(game_date AS STRING)                            AS Date ,
    CONCAT(win_market,' ',win_name,' ',win_pts,
           ' – ',lose_pts,' ',lose_market,' ',lose_name) AS Matchup_or_Venue ,
    (win_pts - lose_pts)                                 AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE round = 2              -- title game
    AND season > 2015          -- 2016 season forward
  ORDER BY Key_Metric DESC
  LIMIT 5
),

-- 3) highest combined-score games since 2011
high_scoring AS (
  SELECT
    'Highest Scoring Games'                              AS Category ,
    CAST(MAX(scheduled_date) AS STRING)                  AS Date ,
    ANY_VALUE(CONCAT(market,' vs ',opp_market))          AS Matchup_or_Venue ,
    SUM(points_game)                                     AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams_games_sr`
  WHERE season > 2010
  GROUP BY game_id
  ORDER BY Key_Metric DESC
  LIMIT 5
),

-- 4) games with the most made 3-pointers since 2011
total_threes AS (
  SELECT
    'Total Threes'                                       AS Category ,
    CAST(MAX(scheduled_date) AS STRING)                  AS Date ,
    ANY_VALUE(CONCAT(market,' vs ',opp_market))          AS Matchup_or_Venue ,
    SUM(three_points_made)                               AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams_games_sr`
  WHERE season > 2010
  GROUP BY game_id
  ORDER BY Key_Metric DESC
  LIMIT 5
)

-- unite the four lists
SELECT * FROM top_venues
UNION ALL
SELECT * FROM champ_margins
UNION ALL
SELECT * FROM high_scoring
UNION ALL
SELECT * FROM total_threes
ORDER BY Category , Key_Metric DESC;