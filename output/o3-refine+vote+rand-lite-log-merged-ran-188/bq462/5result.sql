/* ---------------------------------------------------------------
   Four-in-one summary table
   ---------------------------------------------------------------
   1) Top Venues              – largest seating capacities (Date = ‘N/A’)
   2) Biggest Championship    – Nat’l-title games (round = 2) since 2016,
      Margins                   ranked by point margin
   3) Highest Scoring Games   – regular or post-season games since 2011,
                                ranked by combined points
   4) Total Threes            – games since 2011, ranked by combined
                                three-pointers made
----------------------------------------------------------------- */

WITH top_venues AS (
  SELECT
    'Top Venues'        AS category,
    'N/A'               AS date,
    venue_name          AS matchup_or_venue,
    venue_capacity      AS key_metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name, venue_capacity            -- remove duplicates
  ORDER BY venue_capacity DESC
  LIMIT 5
),
champ_margins AS (
  SELECT
    'Biggest Championship Margins'                                            AS category,
    CAST(game_date AS STRING)                                                 AS date,
    CONCAT(win_market,' ',win_name,' vs. ',
           lose_market,' ',lose_name)                                         AS matchup_or_venue,
    win_pts - lose_pts                                                        AS key_metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015                          -- 2016 season forward
    AND round  = 2                             -- title game
  ORDER BY key_metric DESC
  LIMIT 5
),
high_scores AS (
  SELECT
    'Highest Scoring Games'                                                    AS category,
    CAST(scheduled_date AS STRING)                                            AS date,
    CONCAT(h_market,' ',h_name,' vs. ',
           a_market,' ',a_name)                                               AS matchup_or_venue,
    h_points_game + a_points_game                                             AS key_metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010                         -- 2011 season forward
  ORDER BY key_metric DESC
  LIMIT 5
),
total_threes AS (
  SELECT
    'Total Threes'                                                            AS category,
    CAST(scheduled_date AS STRING)                                            AS date,
    CONCAT(h_market,' ',h_name,' vs. ',
           a_market,' ',a_name)                                               AS matchup_or_venue,
    h_three_points_made + a_three_points_made                                 AS key_metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
  ORDER BY key_metric DESC
  LIMIT 5
)

-- Unite the four mini-lists
SELECT *
FROM top_venues

UNION ALL
SELECT *
FROM champ_margins

UNION ALL
SELECT *
FROM high_scores

UNION ALL
SELECT *
FROM total_threes

-- Final presentation: keep each category grouped, largest metric first
ORDER BY category,
         key_metric DESC;