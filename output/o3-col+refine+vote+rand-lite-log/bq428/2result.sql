-- =====================================================================
-- 1.  Find every player–game between 2010-2018 in which the player
--     scored 15+ points in the 2nd period (period = 2).
-- 2.  Count DISTINCT such players per team_market and keep the TOP-5
--     markets with the greatest counts.
-- 3.  For those five markets, return every NCAA Tournament game
--     (2010-2018) they played, labelling each row as a win or loss and
--     including opponent/seed information as described in the data-model
--     documentation.
-- =====================================================================
WITH hot_player_games AS (
  SELECT
    season,
    game_id,
    player_id,
    player_full_name,
    team_market,
    SUM(points_scored) AS second_period_pts
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE period = 2
    AND shot_made = TRUE
    AND points_scored IS NOT NULL
    AND season BETWEEN 2010 AND 2018
  GROUP BY season, game_id, player_id, player_full_name, team_market
  HAVING SUM(points_scored) >= 15            -- 15+ points in 2nd period
),
top5_markets AS (
  SELECT team_market
  FROM (
    SELECT
      team_market,
      COUNT(DISTINCT player_id) AS num_distinct_players,
      RANK() OVER (ORDER BY COUNT(DISTINCT player_id) DESC) AS rnk
    FROM hot_player_games
    GROUP BY team_market
  )
  WHERE rnk <= 5                              -- keep TOP-5
),
-- --------------------  NCAA tournament rows  -------------------------
tourney_rows AS (
  SELECT
    season,
    round,
    game_date,
    'win'  AS label,
    win_seed        AS seed,
    win_market      AS market,
    win_name        AS name,
    win_alias       AS alias,
    win_school_ncaa AS school_ncaa,
    lose_seed       AS opponent_seed,
    lose_market     AS opponent_market,
    lose_name       AS opponent_name,
    lose_alias      AS opponent_alias,
    lose_school_ncaa AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
    AND win_market IN (SELECT team_market FROM top5_markets)

  UNION ALL

  SELECT
    season,
    round,
    game_date,
    'loss' AS label,
    lose_seed        AS seed,
    lose_market      AS market,
    lose_name        AS name,
    lose_alias       AS alias,
    lose_school_ncaa AS school_ncaa,
    win_seed         AS opponent_seed,
    win_market       AS opponent_market,
    win_name         AS opponent_name,
    win_alias        AS opponent_alias,
    win_school_ncaa  AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
    AND lose_market IN (SELECT team_market FROM top5_markets)
)
-- --------------------  Final result  ----------------------------------
SELECT
  season,
  round,
  game_date,
  label,
  seed,
  market,
  name,
  alias,
  school_ncaa,
  opponent_seed,
  opponent_market,
  opponent_name,
  opponent_alias,
  opponent_school_ncaa
FROM tourney_rows
ORDER BY season, game_date, market, label;