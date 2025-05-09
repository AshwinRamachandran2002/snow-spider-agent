WITH
/* ------------ 1. largest venues ------------ */
top_venues AS (
  SELECT
    'Top Venues'                                   AS Category,
    'N/A'                                          AS Date,
    CONCAT(venue_name, ' (', venue_city, ', ', venue_state, ')')
                                                  AS Matchup_or_Venue,
    venue_capacity                                AS Key_Metric,
    ROW_NUMBER() OVER (ORDER BY venue_capacity DESC) AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name, venue_city, venue_state, venue_capacity
),

/* ------------ 2. biggest title-game margins since 2016 ------------ */
biggest_champ AS (
  SELECT
    'Biggest Championship Margins'                AS Category,
    CAST(game_date AS STRING)                     AS Date,
    CONCAT(win_market, ' ', win_name,
           ' vs ',
           lose_market, ' ', lose_name)           AS Matchup_or_Venue,
    ABS(win_pts - lose_pts)                       AS Key_Metric,
    ROW_NUMBER() OVER (ORDER BY ABS(win_pts - lose_pts) DESC) AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015           -- seasons 2016+
    AND round  = 2              -- national-championship game
),

/* ------------ 3. highest combined points since 2011 season ------------ */
highest_scoring AS (
  SELECT
    'Highest Scoring Games'                       AS Category,
    CAST(scheduled_date AS STRING)                AS Date,
    CONCAT(h_market, ' vs ', a_market)            AS Matchup_or_Venue,
    (h_points_game + a_points_game)               AS Key_Metric,
    ROW_NUMBER() OVER (ORDER BY (h_points_game + a_points_game) DESC) AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
),

/* ------------ 4. most combined made 3-pointers since 2011 season ------------ */
total_threes AS (
  SELECT
    'Total Threes'                                AS Category,
    CAST(scheduled_date AS STRING)                AS Date,
    CONCAT(h_market, ' vs ', a_market)            AS Matchup_or_Venue,
    (h_three_points_made + a_three_points_made)   AS Key_Metric,
    ROW_NUMBER() OVER (ORDER BY (h_three_points_made + a_three_points_made) DESC) AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
)

/* ------------ union top-5 from each section ------------ */
SELECT Category, Date, Matchup_or_Venue, Key_Metric
FROM (
  SELECT * FROM top_venues     WHERE rn <= 5
  UNION ALL
  SELECT * FROM biggest_champ  WHERE rn <= 5
  UNION ALL
  SELECT * FROM highest_scoring WHERE rn <= 5
  UNION ALL
  SELECT * FROM total_threes    WHERE rn <= 5
)
ORDER BY Category, Key_Metric DESC;