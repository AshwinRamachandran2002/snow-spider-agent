/* ------------------------------------------------------------
   NCAA Basketball – four “top‑5” leaderboards in one table
   ------------------------------------------------------------
   Columns returned
   1) Category            – one of the four requested lists
   2) Date                – scheduled date of the game   (“N/A” for venues)
   3) Matchup_or_Venue    – game matchup or venue name
   4) Key_Metric          – value being ranked on
---------------------------------------------------------------- */
WITH
/* ---------- 1. Largest venues (capacity) -------------------- */
top_venues AS (
  SELECT
      'Top Venues'                                  AS Category,
      'N/A'                                         AS Date,
      CONCAT(venue_name,' (',venue_city,', ',venue_state,')')
                                                   AS Matchup_or_Venue,
      MAX(venue_capacity)                           AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name, venue_city, venue_state
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* ---------- 2. Biggest National‑Championship margins -------- */
champ_margins AS (
  SELECT
      'Biggest Championship Margins'                AS Category,
      CAST(MIN(scheduled_date) AS STRING)           AS Date,
      CONCAT( MAX(CASE WHEN win  THEN CONCAT(market,' ',name) END),
              ' vs ',
              MAX(CASE WHEN NOT win THEN CONCAT(market,' ',name) END)
            )                                       AS Matchup_or_Venue,
      MAX(points_game) - MIN(points_game)           AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams_games_sr`
  WHERE season > 2015
        AND tournament_type  = 'NCAA'
        AND tournament_round = 'National Championship'
  GROUP BY game_id
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* ---------- 3. Highest‑scoring games since 2011 ------------- */
high_scoring AS (
  SELECT
      'Highest Scoring Games'                       AS Category,
      CAST(MIN(scheduled_date) AS STRING)           AS Date,
      CONCAT( MAX(CASE WHEN home_team THEN CONCAT(market,' ',name) END),
              ' vs ',
              MAX(CASE WHEN NOT home_team THEN CONCAT(market,' ',name) END)
            )                                       AS Matchup_or_Venue,
      SUM(points_game)                              AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams_games_sr`
  WHERE season > 2010
  GROUP BY game_id
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* ---------- 4. Games with most made 3‑pointers since 2011 --- */
total_threes AS (
  SELECT
      'Total Threes'                                AS Category,
      CAST(MIN(scheduled_date) AS STRING)           AS Date,
      CONCAT( MAX(CASE WHEN home_team THEN CONCAT(market,' ',name) END),
              ' vs ',
              MAX(CASE WHEN NOT home_team THEN CONCAT(market,' ',name) END)
            )                                       AS Matchup_or_Venue,
      SUM(three_points_made)                        AS Key_Metric
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams_games_sr`
  WHERE season > 2010
  GROUP BY game_id
  ORDER BY Key_Metric DESC
  LIMIT 5
)

/* ------------ Union all four leaderboards ------------------- */
SELECT * FROM top_venues
UNION ALL
SELECT * FROM champ_margins
UNION ALL
SELECT * FROM high_scoring
UNION ALL
SELECT * FROM total_threes
ORDER BY Category, Key_Metric DESC;