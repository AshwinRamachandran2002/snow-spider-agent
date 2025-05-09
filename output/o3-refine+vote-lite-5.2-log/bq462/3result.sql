WITH
/* 1. Largest venues (capacity) */
top_venues AS (
  SELECT
    'Top Venues'                         AS Category,
    'N/A'                                AS Date,
    CONCAT(venue_name,' (',venue_city,', ',venue_state,')') AS Matchup_or_Venue,
    venue_capacity                       AS Key_Metric          -- seating capacity
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name, venue_city, venue_state, venue_capacity
  ORDER BY venue_capacity DESC
  LIMIT 5
),

/* 2. National‑title games with biggest win margins (since 2016) */
champ_margins AS (
  SELECT
    'Biggest Championship Margins'                       AS Category,
    CAST(game_date AS STRING)                            AS Date,
    CONCAT(win_market,' ',win_name,' vs ',
           lose_market,' ',lose_name)                    AS Matchup_or_Venue,
    ABS(win_pts - lose_pts)                              AS Key_Metric   -- point margin
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015                       -- 2016 season forward
    AND round = 2                           -- championship game (2 teams left)
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* 3. Highest combined‑score games (since 2011) */
high_scoring AS (
  SELECT
    'Highest Scoring Games'                              AS Category,
    CAST(scheduled_date AS STRING)                       AS Date,
    CONCAT(a_market,' ',a_name,' @ ',
           h_market,' ',h_name)                          AS Matchup_or_Venue,
    (a_points + h_points)                                AS Key_Metric   -- total points
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND a_points IS NOT NULL
    AND h_points IS NOT NULL
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* 4. Games with most made 3‑pointers (since 2011) */
three_frenzy AS (
  SELECT
    'Total Threes'                                       AS Category,
    CAST(scheduled_date AS STRING)                       AS Date,
    CONCAT(a_market,' ',a_name,' @ ',
           h_market,' ',h_name)                          AS Matchup_or_Venue,
    (a_three_points_made + h_three_points_made)          AS Key_Metric   -- total made 3‑pt FG
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND a_three_points_made IS NOT NULL
    AND h_three_points_made IS NOT NULL
  ORDER BY Key_Metric DESC
  LIMIT 5
)

/* Combine the four top‑5 lists */
SELECT * FROM top_venues
UNION ALL
SELECT * FROM champ_margins
UNION ALL
SELECT * FROM high_scoring
UNION ALL
SELECT * FROM three_frenzy
ORDER BY Category, Key_Metric DESC;