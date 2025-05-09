-- 1. Find the 5 team markets that had the most DISTINCT players
--    who scored 15+ points in the SECOND period of any game
--    (seasons 2010‑2018, inclusive)

WITH scored_in_period2 AS (
  SELECT
    season,
    game_id,
    team_market,          -- school (e.g. “Kansas”)
    player_id,
    SUM(points_scored) AS period2_pts          -- points the player scored in period 2
  FROM
    `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
        season BETWEEN 2010 AND 2018
    AND period = 2
    AND points_scored IS NOT NULL              -- keep only scoring events
  GROUP BY
    season, game_id, team_market, player_id
),

players_15_plus AS (       -- players who hit the 15‑point threshold
  SELECT DISTINCT
    team_market,
    player_id
  FROM scored_in_period2
  WHERE period2_pts >= 15
),

top5_markets AS (          -- top‑5 markets by count of those players
  SELECT
    team_market  AS market,
    COUNT(DISTINCT player_id) AS num_distinct_players
  FROM players_15_plus
  GROUP BY team_market
  ORDER BY num_distinct_players DESC
  LIMIT 5
),

-- 2. Re‑shape historical tournament table so every row is “this team” vs “opponent”,
--    tagged with win/loss label (per the external data‑model description).

tournament_games_long AS (
  -- winning side
  SELECT
      season,
      round,
      game_date,
      day,
      'win'  AS label,
      win_seed   AS seed,
      win_market AS market,
      win_name   AS name,
      win_alias  AS alias,
      win_school_ncaa AS school_ncaa,
      win_pts    AS points,
      lose_seed  AS opponent_seed,
      lose_market AS opponent_market,
      lose_name   AS opponent_name,
      lose_alias  AS opponent_alias,
      lose_school_ncaa AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018

  UNION ALL

  -- losing side
  SELECT
      season,
      round,
      game_date,
      day,
      'loss' AS label,
      lose_seed  AS seed,
      lose_market AS market,
      lose_name   AS name,
      lose_alias  AS alias,
      lose_school_ncaa AS school_ncaa,
      lose_pts    AS points,
      win_seed    AS opponent_seed,
      win_market  AS opponent_market,
      win_name    AS opponent_name,
      win_alias   AS opponent_alias,
      win_school_ncaa AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
)

-- 3. Return every tournament game (2010‑2018) for the 5 markets found in step 1
SELECT
  tg.*
FROM tournament_games_long AS tg
JOIN top5_markets         AS m
  ON tg.market = m.market
ORDER BY
  tg.market,
  tg.season,
  tg.round;