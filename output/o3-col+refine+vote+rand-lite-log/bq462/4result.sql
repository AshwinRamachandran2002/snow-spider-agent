WITH
-- 1. Top-capacity arenas (school venue list)
top_venues AS (
  SELECT
    'Top Venues'                                            AS category,
    'N/A'                                                   AS date,
    CONCAT(market,' - ',venue_name)                         AS matchup_or_venue,
    CAST(venue_capacity AS INT64)                           AS key_metric,
    ROW_NUMBER() OVER (ORDER BY venue_capacity DESC)        AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
),

-- 2. Title-game blowouts since the 2016 tournament
biggest_champ_margins AS (
  SELECT
    'Biggest Championship Margins'                          AS category,
    CAST(game_date AS STRING)                               AS date,
    CONCAT(win_market,' ',win_name,' vs. ',
           lose_market,' ',lose_name)                       AS matchup_or_venue,
    (win_pts - lose_pts)                                    AS key_metric,
    ROW_NUMBER() OVER (ORDER BY (win_pts - lose_pts) DESC)  AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE round = 2              -- national-championship game
    AND season > 2015          -- 2016 season forward
),

-- 3. Highest combined scores in regular games since 2011 season
highest_scoring AS (
  SELECT
    'Highest Scoring Games'                                 AS category,
    CAST(scheduled_date AS STRING)                          AS date,
    CONCAT(h_market,' ',h_name,' vs. ',
           a_market,' ',a_name)                             AS matchup_or_venue,
    (h_points + a_points)                                   AS key_metric,
    ROW_NUMBER() OVER (ORDER BY (h_points + a_points) DESC) AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_points IS NOT NULL
    AND a_points IS NOT NULL
),

-- 4. Most combined three-pointers made since 2011 season
total_threes AS (
  SELECT
    'Total Threes'                                          AS category,
    CAST(scheduled_date AS STRING)                          AS date,
    CONCAT(h_market,' ',h_name,' vs. ',
           a_market,' ',a_name)                             AS matchup_or_venue,
    (h_three_points_made + a_three_points_made)             AS key_metric,
    ROW_NUMBER() OVER (ORDER BY (h_three_points_made + a_three_points_made) DESC) AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_three_points_made IS NOT NULL
    AND a_three_points_made IS NOT NULL
)

-- Combine the four categories, keep the top 5 rows from each,
-- and present a uniform output.
SELECT
  category          AS Category,
  date              AS Date,
  matchup_or_venue  AS `Matchup or Venue`,
  key_metric        AS `Key Metric`
FROM (
  SELECT * FROM top_venues            WHERE rn <= 5
  UNION ALL
  SELECT * FROM biggest_champ_margins WHERE rn <= 5
  UNION ALL
  SELECT * FROM highest_scoring       WHERE rn <= 5
  UNION ALL
  SELECT * FROM total_threes          WHERE rn <= 5
)
ORDER BY
  Category,
  `Key Metric` DESC;