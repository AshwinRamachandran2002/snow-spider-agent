SELECT *
FROM (
  SELECT
    'Largest Venues' AS Category,
    CAST(NULL AS STRING) AS Date,
    venue_name AS `Matchup or Venue`,
    CAST(venue_capacity AS STRING) AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name, venue_capacity
  ORDER BY venue_capacity DESC
  LIMIT 5
)
UNION ALL
SELECT *
FROM (
  SELECT
    'Biggest Championship Margins' AS Category,
    CAST(game_date AS STRING) AS Date,
    CONCAT(win_market, ' vs ', lose_market) AS `Matchup or Venue`,
    CAST(win_pts - lose_pts AS STRING) AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE game_date >= '2015-01-01' AND round = 2
  ORDER BY (win_pts - lose_pts) DESC
  LIMIT 5
)
UNION ALL
SELECT *
FROM (
  SELECT
    'Highest Scoring Games' AS Category,
    CAST(scheduled_date AS STRING) AS Date,
    CONCAT(h_market, ' vs ', a_market) AS `Matchup or Venue`,
    CAST(h_points_game + a_points_game AS STRING) AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE scheduled_date >= '2010-01-01' AND h_points_game IS NOT NULL AND a_points_game IS NOT NULL
  ORDER BY (h_points_game + a_points_game) DESC
  LIMIT 5
)
UNION ALL
SELECT *
FROM (
  SELECT
    'Most Three-Pointers in a Matchup' AS Category,
    CAST(scheduled_date AS STRING) AS Date,
    CONCAT(h_market, ' vs ', a_market) AS `Matchup or Venue`,
    CAST(h_three_points_made + a_three_points_made AS STRING) AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE scheduled_date >= '2010-01-01' AND h_three_points_made IS NOT NULL AND a_three_points_made IS NOT NULL
  ORDER BY (h_three_points_made + a_three_points_made) DESC
  LIMIT 5
)