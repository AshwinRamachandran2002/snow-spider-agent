WITH
/* ---------- 1.  Top 5 largest venues ---------- */
venue_sizes AS (
  SELECT
    venue_id,
    venue_name,
    venue_city,
    venue_state,
    MAX(venue_capacity) AS capacity   -- (same venue may appear once per team)
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_id, venue_name, venue_city, venue_state
),
top_venues AS (
  SELECT
    'Top Venues'                                      AS Category,
    'N/A'                                             AS Date,
    CONCAT(venue_name,' (',venue_city,
           IFNULL(CONCAT(', ',venue_state),''),')')   AS `Matchup or Venue`,
    capacity                                          AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY capacity DESC)        AS rn
  FROM venue_sizes
)
  
/* ---------- 2.  Top 5 biggest National‑Championship margins since 2016 ---------- */
, champ_margins AS (
  SELECT
    'Biggest Championship Margins'                                        AS Category,
    CAST(game_date AS STRING)                                             AS Date,
    CONCAT(win_market,' vs ',lose_market)                                 AS `Matchup or Venue`,
    (win_pts - lose_pts)                                                  AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY (win_pts - lose_pts) DESC)                AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015          -- 2016 season forward
    AND round = 2              -- National Championship (2 teams left)
)

/* ---------- 3.  Top 5 highest‑scoring games (total points) since 2011 ---------- */
, game_totals AS (
  SELECT
    'Highest Scoring Games'                                               AS Category,
    CAST(scheduled_date AS STRING)                                        AS Date,
    CONCAT(a_market,' vs ',h_market)                                      AS `Matchup or Venue`,
    COALESCE(a_points, a_points_game, 0) +
    COALESCE(h_points, h_points_game, 0)                                  AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY
                       COALESCE(a_points, a_points_game, 0) +
                       COALESCE(h_points, h_points_game, 0) DESC)         AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
)

/* ---------- 4.  Top 5 games with most made 3‑pointers since 2011 ---------- */
, game_threes AS (
  SELECT
    'Total Threes'                                                        AS Category,
    CAST(scheduled_date AS STRING)                                        AS Date,
    CONCAT(a_market,' vs ',h_market)                                      AS `Matchup or Venue`,
    COALESCE(a_three_points_made,0) + COALESCE(h_three_points_made,0)     AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY
                       COALESCE(a_three_points_made,0) +
                       COALESCE(h_three_points_made,0) DESC)              AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
)

/* ---------- Combine the four top‑5 lists ---------- */
SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM top_venues  WHERE rn <= 5

UNION ALL
SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM champ_margins WHERE rn <= 5

UNION ALL
SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM game_totals  WHERE rn <= 5

UNION ALL
SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM game_threes  WHERE rn <= 5

ORDER BY Category,
         `Key Metric` DESC;