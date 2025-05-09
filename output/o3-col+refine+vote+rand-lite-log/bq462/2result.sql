WITH
/* ---------- 1.  Top-5 largest arenas ---------- */
top_venues AS (
  SELECT
    'Top Venues'                                           AS Category ,
    'N/A'                                                  AS Date ,
    CONCAT(venue_name,' (',market,')')                     AS `Matchup or Venue` ,
    venue_capacity                                         AS Key_Metric
  FROM (
      SELECT DISTINCT venue_id , venue_name , market , venue_capacity
      FROM   `bigquery-public-data.ncaa_basketball.mbb_teams`
      WHERE  venue_capacity IS NOT NULL
  )
  ORDER BY venue_capacity DESC
  LIMIT 5
),

/* ---------- 2.  Top-5 biggest championship winning margins (since 2016 title games) ---------- */
champ_margins AS (
  SELECT
    'Biggest Championship Margins'                         AS Category ,
    CAST(game_date AS STRING)                              AS Date ,
    CONCAT(win_market,' ',win_name,' vs ',
           lose_market,' ',lose_name)                      AS `Matchup or Venue` ,
    (win_pts - lose_pts)                                   AS Key_Metric
  FROM   `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE  season > 2015        -- 2016 season forward
    AND  round  = 2           -- National-Championship game (2 teams left)
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* ---------- 3.  Top-5 highest scoring games (total pts, since 2011) ---------- */
hi_scores AS (
  SELECT
    'Highest Scoring Games'                                AS Category ,
    CAST(scheduled_date AS STRING)                         AS Date ,
    CONCAT(a_market,' ',a_name,' @ ',
           h_market,' ',h_name)                            AS `Matchup or Venue` ,
    (h_points + a_points)                                  AS Key_Metric
  FROM   `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE  season > 2010
  ORDER BY Key_Metric DESC
  LIMIT 5
),

/* ---------- 4.  Top-5 games with most made 3-pointers (since 2011) ---------- */
hi_threes AS (
  SELECT
    'Total Threes'                                         AS Category ,
    CAST(scheduled_date AS STRING)                         AS Date ,
    CONCAT(a_market,' ',a_name,' @ ',
           h_market,' ',h_name)                            AS `Matchup or Venue` ,
    (h_three_points_made + a_three_points_made)            AS Key_Metric
  FROM   `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE  season > 2010
  ORDER BY Key_Metric DESC
  LIMIT 5
)

/* ---------- Final combined table ---------- */
SELECT * FROM top_venues
UNION ALL
SELECT * FROM champ_margins
UNION ALL
SELECT * FROM hi_scores
UNION ALL
SELECT * FROM hi_threes;