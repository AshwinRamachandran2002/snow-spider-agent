WITH
/* 1) Largest arenas by listed seating capacity ------------------------------*/
top_venues AS (
  SELECT
    'Top Venues'               AS Category,
    'N/A'                      AS Date,
    CONCAT(venue_name,
           ' (', venue_city, ', ', venue_state, ')')  AS Matchup_or_Venue,
    venue_capacity             AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY                                   -- multiple teams can share a venue
        venue_name, venue_city, venue_state, venue_capacity
  ORDER BY venue_capacity DESC
  LIMIT 5
),

/* 2) Biggest NCAA‑title game blow‑outs (since the 2016 tournament) ----------*/
champ_margins AS (
  SELECT
    'Biggest Championship Margins'           AS Category,
    CAST(scheduled_date AS STRING)           AS Date,
    CONCAT(a_market,' ',a_name,' vs ',
           h_market,' ',h_name)              AS Matchup_or_Venue,
    ABS(h_points - a_points)                 AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2015
    AND tournament IS NOT NULL
    AND LOWER(tournament_round) LIKE '%championship%'     -- title game
    AND (LOWER(tournament)     LIKE '%ncaa%'
         OR LOWER(tournament_type) LIKE '%ncaa%')         -- NCAA tournament
    AND h_points IS NOT NULL
    AND a_points IS NOT NULL
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* 3) Highest combined‑score games (since 2011 season) -----------------------*/
high_scoring AS (
  SELECT
    'Highest Scoring Games'                  AS Category,
    CAST(scheduled_date AS STRING)           AS Date,
    CONCAT(a_market,' ',a_name,' vs ',
           h_market,' ',h_name)              AS Matchup_or_Venue,
    (h_points + a_points)                    AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_points IS NOT NULL
    AND a_points IS NOT NULL
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* 4) Games with most made 3‑pointers combined (since 2011 season) -----------*/
total_threes AS (
  SELECT
    'Total Threes'                           AS Category,
    CAST(scheduled_date AS STRING)           AS Date,
    CONCAT(a_market,' ',a_name,' vs ',
           h_market,' ',h_name)              AS Matchup_or_Venue,
    (h_three_points_made + a_three_points_made) AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_three_points_made IS NOT NULL
    AND a_three_points_made IS NOT NULL
  ORDER BY Key_Metric DESC
  LIMIT 5
)

/* --------------------------------------------------------------------------*/
SELECT * FROM top_venues
UNION ALL
SELECT * FROM champ_margins
UNION ALL
SELECT * FROM high_scoring
UNION ALL
SELECT * FROM total_threes;