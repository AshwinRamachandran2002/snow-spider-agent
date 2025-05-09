WITH
/* ---------- 1. five largest venues ---------- */
top_venues AS (
  SELECT
    venue_name,
    venue_capacity
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name, venue_capacity
  ORDER BY venue_capacity DESC
  LIMIT 5
),

/* ---------- 2. biggest national‑title winning margins since 2016 ---------- */
biggest_champ_margins AS (
  SELECT
    game_date,
    win_market,
    lose_market,
    win_pts,
    lose_pts,
    (win_pts - lose_pts) AS margin
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015                -- 2016 season forward
    AND round = 2                    -- National Championship game
  ORDER BY margin DESC
  LIMIT 5
),

/* ---------- 3. highest‑scoring games (total points) since 2011 ---------- */
highest_scoring AS (
  SELECT
    scheduled_date,
    h_market,
    a_market,
    (h_points + a_points) AS total_pts
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_points IS NOT NULL
    AND a_points IS NOT NULL
  ORDER BY total_pts DESC
  LIMIT 5
),

/* ---------- 4. games with most combined made threes since 2011 ---------- */
most_threes AS (
  SELECT
    scheduled_date,
    h_market,
    a_market,
    (h_three_points_made + a_three_points_made) AS threes_made
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
    AND h_three_points_made IS NOT NULL
    AND a_three_points_made IS NOT NULL
  ORDER BY threes_made DESC
  LIMIT 5
)

/* ---------- assemble final answer ---------- */
SELECT
  Category,
  Date,
  `Matchup or Venue`,
  `Key Metric`
FROM (
  /* Top Venues */
  SELECT
    'Top Venues'                         AS Category,
    'N/A'                                AS Date,
    venue_name                           AS `Matchup or Venue`,
    CAST(venue_capacity AS STRING)       AS `Key Metric`,
    1                                     AS sort_cat,
    venue_capacity                        AS sort_val
  FROM top_venues

  UNION ALL

  /* Biggest Championship Margins */
  SELECT
    'Biggest Championship Margins'        AS Category,
    CAST(game_date AS STRING)             AS Date,
    CONCAT(win_market, ' vs ', lose_market) AS `Matchup or Venue`,
    CAST(margin AS STRING)                AS `Key Metric`,
    2                                     AS sort_cat,
    margin                                AS sort_val
  FROM biggest_champ_margins

  UNION ALL

  /* Highest Scoring Games */
  SELECT
    'Highest Scoring Games'               AS Category,
    CAST(scheduled_date AS STRING)        AS Date,
    CONCAT(h_market, ' vs ', a_market)    AS `Matchup or Venue`,
    CAST(total_pts AS STRING)             AS `Key Metric`,
    3                                     AS sort_cat,
    total_pts                             AS sort_val
  FROM highest_scoring

  UNION ALL

  /* Total Threes */
  SELECT
    'Total Threes'                        AS Category,
    CAST(scheduled_date AS STRING)        AS Date,
    CONCAT(h_market, ' vs ', a_market)    AS `Matchup or Venue`,
    CAST(threes_made AS STRING)           AS `Key Metric`,
    4                                     AS sort_cat,
    threes_made                           AS sort_val
  FROM most_threes
)
ORDER BY
  sort_cat,
  sort_val DESC;