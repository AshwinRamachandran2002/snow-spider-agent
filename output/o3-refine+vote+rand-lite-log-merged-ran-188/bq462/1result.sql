/*  Top-5 records for each requested category, combined in one table  */
WITH
/* ------------------------------------------------------------ */
/* 1) Largest arenas (venue list)                                */
top_venues AS (
  SELECT
    'Top Venues – Capacity'                AS Category,
    'N/A'                                  AS Date,
    CONCAT(market,' – ',venue_name)        AS Matchup_or_Venue,
    venue_capacity                         AS Key_Metric          -- seats
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  ORDER BY venue_capacity DESC
  LIMIT 5
),

/* ------------------------------------------------------------ */
/* 2) Biggest margins in the national-title game (2016-season forward) */
biggest_champ_margins AS (
  SELECT
    'Biggest Championship Margins'                           AS Category,
    CAST(game_date AS STRING)                                AS Date,
    CONCAT(win_market,' ',win_name,' vs ',
           lose_market,' ',lose_name)                        AS Matchup_or_Venue,
    (win_pts - lose_pts)                                     AS Key_Metric  -- margin
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015          -- 2016 tournament onward
    AND round  = 2             -- title game
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* ------------------------------------------------------------ */
/* 3) Highest-scoring games (combined points, 2011-season forward) */
highest_scoring_games AS (
  SELECT
    'Highest Scoring Games'                                   AS Category,
    CAST(scheduled_date AS STRING)                            AS Date,
    CONCAT(h_market,' ',h_name,' vs ',
           a_market,' ',a_name)                               AS Matchup_or_Venue,
    (h_points_game + a_points_game)                           AS Key_Metric  -- total points
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* ------------------------------------------------------------ */
/* 4) Games with the most made 3-pointers (2011-season forward) */
most_threes_games AS (
  SELECT
    'Total Threes'                                            AS Category,
    CAST(scheduled_date AS STRING)                            AS Date,
    CONCAT(h_market,' ',h_name,' vs ',
           a_market,' ',a_name)                               AS Matchup_or_Venue,
    (h_three_points_made + a_three_points_made)               AS Key_Metric  -- made threes
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
  ORDER BY Key_Metric DESC
  LIMIT 5
)

/* ------------------------------------------------------------ */
SELECT * FROM top_venues
UNION ALL
SELECT * FROM biggest_champ_margins
UNION ALL
SELECT * FROM highest_scoring_games
UNION ALL
SELECT * FROM most_threes_games
ORDER BY Category, Key_Metric DESC;