-- Top‑5 lists for four requested categories
WITH top_venues AS (
  SELECT
    'Top Venues'                        AS Category,
    'N/A'                               AS Date,
    CONCAT(venue_name,' (',venue_city,', ',venue_state,')')
                                         AS Matchup_or_Venue,
    CAST(venue_capacity AS STRING)      AS Key_Metric
  FROM (
    SELECT DISTINCT
      venue_id,
      venue_name,
      venue_city,
      venue_state,
      venue_capacity
    FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
    WHERE venue_capacity IS NOT NULL
  )
  ORDER BY venue_capacity DESC
  LIMIT 5
),
biggest_champ_margins AS (
  SELECT
    'Biggest Championship Margins'      AS Category,
    CAST(game_date AS STRING)           AS Date,
    CONCAT(win_market,' ',win_name,' vs ',
           lose_market,' ',lose_name)   AS Matchup_or_Venue,
    CAST(win_pts - lose_pts AS STRING)  AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015         -- 2016 season onward
    AND round  = 2            -- National‑Championship game (2 teams left)
  ORDER BY (win_pts - lose_pts) DESC
  LIMIT 5
),
highest_scoring_games AS (
  SELECT
    'Highest Scoring Games'             AS Category,
    CAST(scheduled_date AS STRING)      AS Date,
    CONCAT(a_market,' ',a_name,' vs ',
           h_market,' ',h_name)         AS Matchup_or_Venue,
    CAST(a_points + h_points AS STRING) AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010                   -- 2011 season onward
    AND a_points IS NOT NULL
    AND h_points IS NOT NULL
  ORDER BY (a_points + h_points) DESC
  LIMIT 5
),
total_threes AS (
  SELECT
    'Total Threes'                      AS Category,
    CAST(scheduled_date AS STRING)      AS Date,
    CONCAT(a_market,' ',a_name,' vs ',
           h_market,' ',h_name)         AS Matchup_or_Venue,
    CAST(a_three_points_made + h_three_points_made AS STRING)
                                         AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND a_three_points_made IS NOT NULL
    AND h_three_points_made IS NOT NULL
  ORDER BY (a_three_points_made + h_three_points_made) DESC
  LIMIT 5
)

-- Combine the four sub‑lists
SELECT * FROM top_venues
UNION ALL
SELECT * FROM biggest_champ_margins
UNION ALL
SELECT * FROM highest_scoring_games
UNION ALL
SELECT * FROM total_threes;