WITH
  largest_venues AS (
    SELECT
      'Largest Venues' AS Category,
      'N/A' AS Date,
      venue_name AS `Matchup or Venue`,
      CAST(venue_capacity AS STRING) AS `Key Metric`,
      ROW_NUMBER() OVER (ORDER BY venue_capacity DESC) AS rn
    FROM (
      SELECT DISTINCT venue_name, venue_capacity
      FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
      WHERE venue_capacity IS NOT NULL
    )
  ),
  biggest_championship_margins AS (
    SELECT
      'Biggest Championship Margins' AS Category,
      CAST(game_date AS STRING) AS Date,
      CONCAT(win_market, ' vs ', lose_market) AS `Matchup or Venue`,
      CAST(win_pts - lose_pts AS STRING) AS `Key Metric`,
      ROW_NUMBER() OVER (ORDER BY (win_pts - lose_pts) DESC) AS rn
    FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
    WHERE season >= 2015 AND round = 2
  ),
  highest_scoring_games AS (
    SELECT
      'Highest Scoring Games' AS Category,
      CAST(gametime AS STRING) AS Date,
      CONCAT(h_market, ' vs ', a_market) AS `Matchup or Venue`,
      CAST(h_points_game + a_points_game AS STRING) AS `Key Metric`,
      ROW_NUMBER() OVER (ORDER BY (h_points_game + a_points_game) DESC) AS rn
    FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
    WHERE season >= 2010
  ),
  most_three_pointers_matchup AS (
    SELECT
      'Most Three-Pointers in a Matchup' AS Category,
      CAST(gametime AS STRING) AS Date,
      CONCAT(h_market, ' vs ', a_market) AS `Matchup or Venue`,
      CAST(h_three_points_made + a_three_points_made AS STRING) AS `Key Metric`,
      ROW_NUMBER() OVER (ORDER BY (h_three_points_made + a_three_points_made) DESC) AS rn
    FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
    WHERE season >= 2010
  )
SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM largest_venues
WHERE rn <= 5

UNION ALL

SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM biggest_championship_margins
WHERE rn <= 5

UNION ALL

SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM highest_scoring_games
WHERE rn <= 5

UNION ALL

SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM most_three_pointers_matchup
WHERE rn <= 5