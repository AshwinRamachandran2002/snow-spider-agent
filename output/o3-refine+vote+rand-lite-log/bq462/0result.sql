WITH
/* ---------- 1.  Top Venues ---------- */
venues_raw AS (
  SELECT
    venue_name,
    MAX(venue_capacity) AS capacity          -- if same venue appears for several teams keep largest listed capacity
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name
),
venues_ranked AS (
  SELECT
    'Top Venues'                  AS Category,
    'N/A'                         AS Date,
    venue_name                    AS `Matchup or Venue`,
    capacity                      AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY capacity DESC, venue_name) AS rn
  FROM venues_raw
)
SELECT Category, Date, `Matchup or Venue`, `Key Metric`
FROM venues_ranked
WHERE rn <= 5

UNION ALL
/* ---------- 2.  Biggest Championship Margins (since 2016 title game) ---------- */
SELECT
  'Biggest Championship Margins'                                              AS Category,
  CAST(game_date AS STRING)                                                   AS Date,
  CONCAT(win_market,' ',win_name,' (',win_pts,')  –  ',
         lose_market,' ',lose_name,' (',lose_pts,')')                         AS `Matchup or Venue`,
  ABS(win_pts - lose_pts)                                                     AS `Key Metric`
FROM (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY ABS(win_pts - lose_pts) DESC, game_date) AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015            -- 2016 season forward
    AND round  = 2               -- 2 teams left  = national championship
)
WHERE rn <= 5

UNION ALL
/* ---------- 3.  Highest‑Scoring Games (since 2011) ---------- */
SELECT
  'Highest Scoring Games'                                                     AS Category,
  CAST(scheduled_date AS STRING)                                              AS Date,
  CONCAT(a_market,' ',a_name,' (',a_points_game,')  –  ',
         h_market,' ',h_name,' (',h_points_game,')')                          AS `Matchup or Venue`,
  (a_points_game + h_points_game)                                             AS `Key Metric`
FROM (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY (a_points_game + h_points_game) DESC,
                                      scheduled_date)                         AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND a_points_game IS NOT NULL
    AND h_points_game IS NOT NULL
)
WHERE rn <= 5

UNION ALL
/* ---------- 4.  Most Three‑Pointers Combined (since 2011) ---------- */
SELECT
  'Total Threes'                                                              AS Category,
  CAST(scheduled_date AS STRING)                                              AS Date,
  CONCAT(a_market,' ',a_name,' vs. ',h_market,' ',h_name)                     AS `Matchup or Venue`,
  (COALESCE(a_three_points_made,0) + COALESCE(h_three_points_made,0))         AS `Key Metric`
FROM (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY (COALESCE(a_three_points_made,0) +
                                      COALESCE(h_three_points_made,0)) DESC,
                                      scheduled_date)                         AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
)
WHERE rn <= 5

ORDER BY Category, `Key Metric` DESC;