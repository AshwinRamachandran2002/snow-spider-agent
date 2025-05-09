WITH
/* 1)  Five largest arenas used by NCAA men’s teams */
top_venues AS (
  SELECT
    'Top Venues'        AS `Category`,
    'N/A'               AS `Date`,
    venue_name          AS `Matchup or Venue`,
    MAX(venue_capacity) AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name
  ORDER BY `Key Metric` DESC, venue_name
  LIMIT 5
),

/* 2)  Biggest winning margins in national‑title games, 2016 season onward */
champ_margins AS (
  SELECT
    'Biggest Championship Margins'                         AS `Category`,
    CAST(game_date AS STRING)                              AS `Date`,
    CONCAT(win_market, ' ', win_name,
           ' vs. ',
           lose_market, ' ', lose_name)                    AS `Matchup or Venue`,
    ABS(win_pts - lose_pts)                                AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015            -- seasons 2016+
    AND round = 2                -- championship game
  ORDER BY `Key Metric` DESC, game_date
  LIMIT 5
),

/* 3)  Highest combined points in any game since the 2011 season */
high_scores AS (
  SELECT
    'Highest Scoring Games'                                 AS `Category`,
    CAST(scheduled_date AS STRING)                          AS `Date`,
    CONCAT(h_market, ' ', h_name,
           ' vs. ',
           a_market, ' ', a_name)                           AS `Matchup or Venue`,
    (h_points + a_points)                                   AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_points IS NOT NULL
    AND a_points IS NOT NULL
  ORDER BY `Key Metric` DESC, scheduled_date
  LIMIT 5
),

/* 4)  Games with the most made three‑pointers combined, since the 2011 season */
high_threes AS (
  SELECT
    'Total Threes'                                          AS `Category`,
    CAST(scheduled_date AS STRING)                          AS `Date`,
    CONCAT(h_market, ' ', h_name,
           ' vs. ',
           a_market, ' ', a_name)                           AS `Matchup or Venue`,
    (h_three_points_made + a_three_points_made)             AS `Key Metric`
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_three_points_made IS NOT NULL
    AND a_three_points_made IS NOT NULL
  ORDER BY `Key Metric` DESC, scheduled_date
  LIMIT 5
)

/* Combine the four leaderboards */
SELECT * FROM top_venues
UNION ALL
SELECT * FROM champ_margins
UNION ALL
SELECT * FROM high_scores
UNION ALL
SELECT * FROM high_threes
ORDER BY `Category`, `Key Metric` DESC;