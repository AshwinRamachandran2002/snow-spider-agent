/*----------------------------------------------------------------
  20-row summary table (5 rows per requested category)
----------------------------------------------------------------*/
WITH
/* 1. Top Venues ------------------------------------------------*/
top_venues AS (
  SELECT
    'Top Venues'                     AS category,
    'N/A'                            AS date,
    venue_name                       AS matchup_or_venue,
    MAX(venue_capacity)              AS key_metric          -- capacity
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name
  ORDER BY key_metric DESC
  LIMIT 5
),

/* 2. Biggest Championship Margins -----------------------------*/
title_margins AS (
  SELECT
    'Biggest Championship Margins'                                   AS category,
    CAST(game_date AS STRING)                                        AS date,
    CONCAT(win_market,' ',win_name,' vs ',
           lose_market,' ',lose_name)                                AS matchup_or_venue,
    ABS(win_pts - lose_pts)                                          AS key_metric  -- margin
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015          -- 2016 season forward
    AND round  = 2             -- national-title game
  ORDER BY key_metric DESC
  LIMIT 5
),

/* 3. Highest Scoring Games ------------------------------------*/
high_scores AS (
  SELECT
    'Highest Scoring Games'                                          AS category,
    CAST(scheduled_date AS STRING)                                   AS date,
    CONCAT(a_market,' ',a_name,' @ ',
           h_market,' ',h_name)                                      AS matchup_or_venue,
    (a_points_game + h_points_game)                                  AS key_metric  -- total points
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010           -- 2011 season forward
  ORDER BY key_metric DESC
  LIMIT 5
),

/* 4. Total Threes ---------------------------------------------*/
three_fests AS (
  SELECT
    'Total Threes'                                                   AS category,
    CAST(scheduled_date AS STRING)                                   AS date,
    CONCAT(a_market,' ',a_name,' @ ',
           h_market,' ',h_name)                                      AS matchup_or_venue,
    (a_three_points_made + h_three_points_made)                      AS key_metric  -- made 3-pt FG
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010           -- 2011 season forward
  ORDER BY key_metric DESC
  LIMIT 5
)

/* ------------ Final 20-row output ----------------------------*/
SELECT * FROM top_venues
UNION ALL
SELECT * FROM title_margins
UNION ALL
SELECT * FROM high_scores
UNION ALL
SELECT * FROM three_fests
ORDER BY category, key_metric DESC;