/* -----------------------------------------------------------
   Top Venues, Biggest Championship Margins, Highest Scoring
   Games, and Total Threes – top‑5 records for each category
   ----------------------------------------------------------- */
WITH
/* ---------- 1. Top Venues (capacity) ---------- */
top_venues AS (
  SELECT
      'Top Venues'                        AS Category,
      'N/A'                               AS Date,
      CONCAT(venue_name,' (',venue_city,', ',venue_state,')')
                                           AS Matchup_or_Venue,
      CAST(venue_capacity AS STRING)      AS Key_Metric,
      ROW_NUMBER() OVER(ORDER BY venue_capacity DESC) AS rn
  FROM (
        /* one row per venue_id to avoid duplicates */
        SELECT
          venue_id,
          ANY_VALUE(venue_name)  AS venue_name,
          ANY_VALUE(venue_city)  AS venue_city,
          ANY_VALUE(venue_state) AS venue_state,
          MAX(venue_capacity)    AS venue_capacity
        FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
        WHERE venue_capacity IS NOT NULL
        GROUP BY venue_id
       )
  ORDER BY venue_capacity DESC
  LIMIT 5
),

/* ---------- 2. Biggest Championship Margins ---------- */
big_champ_margins AS (
  SELECT
      'Biggest Championship Margins'      AS Category,
      CAST(game_date AS STRING)           AS Date,
      CONCAT(win_market,' ',win_name,' vs ',
             lose_market,' ',lose_name)   AS Matchup_or_Venue,
      CAST(win_pts - lose_pts AS STRING)  AS Key_Metric,
      ROW_NUMBER() OVER(
          ORDER BY win_pts - lose_pts DESC, game_date DESC)      AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season  > 2015          -- since 2016 season
    AND round   = 2             -- National Championship game
  ORDER BY win_pts - lose_pts DESC
  LIMIT 5
),

/* ---------- 3. Highest Scoring Games ---------- */
high_score_games AS (
  SELECT
      'Highest Scoring Games'             AS Category,
      CAST(scheduled_date AS STRING)      AS Date,
      CONCAT(a_market,' ',a_name,' @ ',
             h_market,' ',h_name)         AS Matchup_or_Venue,
      CAST(total_points AS STRING)        AS Key_Metric,
      ROW_NUMBER() OVER(
          ORDER BY total_points DESC, scheduled_date DESC)       AS rn
  FROM (
        SELECT
          scheduled_date,
          h_market, h_name, a_market, a_name,
          /* some rows store points in *_points_game, others in *_points */
          COALESCE(h_points_game,h_points,0) AS hp,
          COALESCE(a_points_game,a_points,0) AS ap,
          COALESCE(h_points_game,h_points,0) +
          COALESCE(a_points_game,a_points,0) AS total_points
        FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
        WHERE season > 2010                -- since 2011 season
          AND (COALESCE(h_points_game,h_points) IS NOT NULL)
          AND (COALESCE(a_points_game,a_points) IS NOT NULL)
       )
  ORDER BY total_points DESC
  LIMIT 5
),

/* ---------- 4. Total Threes (made) ---------- */
total_threes AS (
  SELECT
      'Total Threes'                      AS Category,
      CAST(scheduled_date AS STRING)      AS Date,
      CONCAT(a_market,' ',a_name,' @ ',
             h_market,' ',h_name)         AS Matchup_or_Venue,
      CAST(total_threes AS STRING)        AS Key_Metric,
      ROW_NUMBER() OVER(
          ORDER BY total_threes DESC, scheduled_date DESC)       AS rn
  FROM (
        SELECT
          scheduled_date,
          h_market, h_name, a_market, a_name,
          COALESCE(h_three_points_made,0) +
          COALESCE(a_three_points_made,0)  AS total_threes
        FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
        WHERE season > 2010                -- since 2011 season
          AND (h_three_points_made IS NOT NULL
               OR a_three_points_made IS NOT NULL)
       )
  ORDER BY total_threes DESC
  LIMIT 5
)

/* ---------- Final union & ordering ---------- */
SELECT Category, Date, Matchup_or_Venue, Key_Metric
FROM (
      SELECT * FROM top_venues
      UNION ALL
      SELECT * FROM big_champ_margins
      UNION ALL
      SELECT * FROM high_score_games
      UNION ALL
      SELECT * FROM total_threes
     )
ORDER BY Category, rn;