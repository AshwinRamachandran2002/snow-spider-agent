WITH
/* ---------- 1.  TOP VENUES ---------- */
venues AS (
  SELECT DISTINCT
         venue_id,
         venue_name,
         venue_city,
         venue_state,
         venue_capacity
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
),
top_venues AS (
  SELECT
      'Top Venues'                                   AS Category,
      'N/A'                                          AS Date,
      CONCAT(venue_name,
             ' (', venue_city,
             IF(venue_state IS NOT NULL, CONCAT(', ', venue_state), ''), ')')
                                                     AS Matchup_or_Venue,
      venue_capacity                                 AS Key_Metric
  FROM venues
  ORDER BY venue_capacity DESC
  LIMIT 5
),

/* ---------- 2.  BIGGEST CHAMPIONSHIP MARGINS (since 2016) ---------- */
champ_games AS (
  SELECT
      game_id,
      scheduled_date,
      ARRAY_AGG(STRUCT(market, name, points_game)
                ORDER BY points_game DESC)           AS teams
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams_games_sr`
  WHERE season > 2015
    AND LOWER(tournament_round) LIKE '%championship%'    -- catches “National Championship”
    AND tournament_type = 'NCAA'
  GROUP BY game_id, scheduled_date
),
biggest_champ_margins AS (
  SELECT
      'Biggest Championship Margins'                AS Category,
      CAST(scheduled_date AS STRING)                AS Date,
      CONCAT(teams[OFFSET(0)].market, ' ', teams[OFFSET(0)].name,
             ' vs ',
             teams[OFFSET(1)].market, ' ', teams[OFFSET(1)].name) AS Matchup_or_Venue,
      (teams[OFFSET(0)].points_game
       - teams[OFFSET(1)].points_game)              AS Key_Metric
  FROM champ_games
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* ---------- 3 & 4.  GAME‑LEVEL STATS SINCE 2011 ---------- */
game_stats AS (
  SELECT
      game_id,
      scheduled_date,
      SUM(points_game)         AS total_points,
      SUM(three_points_made)   AS total_threes,
      ARRAY_AGG(STRUCT(market, name) ORDER BY market) AS teams
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams_games_sr`
  WHERE season > 2010
  GROUP BY game_id, scheduled_date
  HAVING COUNT(DISTINCT market) = 2                 -- ensure exactly two teams
),
highest_scoring AS (
  SELECT
      'Highest Scoring Games'                       AS Category,
      CAST(scheduled_date AS STRING)                AS Date,
      CONCAT(teams[OFFSET(0)].market, ' ', teams[OFFSET(0)].name,
             ' vs ',
             teams[OFFSET(1)].market, ' ', teams[OFFSET(1)].name) AS Matchup_or_Venue,
      total_points                                  AS Key_Metric
  FROM game_stats
  ORDER BY total_points DESC
  LIMIT 5
),
total_threes AS (
  SELECT
      'Total Threes'                                AS Category,
      CAST(scheduled_date AS STRING)                AS Date,
      CONCAT(teams[OFFSET(0)].market, ' ', teams[OFFSET(0)].name,
             ' vs ',
             teams[OFFSET(1)].market, ' ', teams[OFFSET(1)].name) AS Matchup_or_Venue,
      total_threes                                  AS Key_Metric
  FROM game_stats
  ORDER BY total_threes DESC
  LIMIT 5
)

/* ---------- FINAL UNION ---------- */
SELECT * FROM top_venues
UNION ALL
SELECT * FROM biggest_champ_margins
UNION ALL
SELECT * FROM highest_scoring
UNION ALL
SELECT * FROM total_threes
ORDER BY Category, Key_Metric DESC;