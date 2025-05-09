/* -----------------------------------------------------------
   Top‑5 records for four NCAA‑basketball “best‑of” categories
   ----------------------------------------------------------- */
WITH
/* ---------- 1) largest arenas ---------- */
top_venues AS (
  SELECT
    'Top Venues'                                           AS Category,
    'N/A'                                                  AS Date,
    CONCAT(venue_name,' – ',market)                        AS `Matchup or Venue`,
    venue_capacity                                         AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  ORDER BY venue_capacity DESC
  LIMIT 5
),

/* ---------- 2) biggest title‑game margins since 2016 ---------- */
champ_margins AS (
  SELECT
    'Biggest Championship Margins'                         AS Category,
    CAST(game_date AS STRING)                              AS Date,
    CONCAT(win_market,' ',win_name,
           ' def. ',
           lose_market,' ',lose_name)                      AS `Matchup or Venue`,
    (win_pts - lose_pts)                                   AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015              -- 2016 title game onward
    AND round  = 2                 -- National‑Championship
  ORDER BY `Key Metric` DESC
  LIMIT 5
),

/* ---------- 3) highest scoring games since 2011 ---------- */
hi_scores AS (
  SELECT
    'Highest Scoring Games'                                AS Category,
    CAST(scheduled_date AS STRING)                         AS Date,
    CONCAT(h_market,' ',h_name,
           ' vs. ',
           a_market,' ',a_name)                            AS `Matchup or Venue`,
    (h_points + a_points)                                  AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_points IS NOT NULL
    AND a_points IS NOT NULL
  ORDER BY `Key Metric` DESC
  LIMIT 5
),

/* ---------- 4) most combined made 3‑pointers since 2011 ---------- */
hi_threes AS (
  SELECT
    'Total Threes'                                         AS Category,
    CAST(scheduled_date AS STRING)                         AS Date,
    CONCAT(h_market,' ',h_name,
           ' vs. ',
           a_market,' ',a_name)                            AS `Matchup or Venue`,
    (h_three_points_made + a_three_points_made)            AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_three_points_made IS NOT NULL
    AND a_three_points_made IS NOT NULL
  ORDER BY `Key Metric` DESC
  LIMIT 5
)

/* ---------- union all four result sets & present ---------- */
SELECT
  Category,
  Date,
  `Matchup or Venue`,
  `Key Metric`
FROM (
  SELECT * FROM top_venues
  UNION ALL
  SELECT * FROM champ_margins
  UNION ALL
  SELECT * FROM hi_scores
  UNION ALL
  SELECT * FROM hi_threes
)
ORDER BY Category, `Key Metric` DESC;