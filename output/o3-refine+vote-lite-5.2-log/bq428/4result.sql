/* ---------------------------------------------------------
   TOP‑5 MARKETS (2010‑2018) WITH MOST DISTINCT PLAYERS
   WHO SCORED ≥15 PTS IN 2nd PERIOD OF ANY GAME,
   THEN EVERY NCAA TOURNAMENT GAME (2010‑2018)
   IN WHICH THOSE MARKETS APPEAR
----------------------------------------------------------*/

WITH player_second_period AS (   -- every player/game with ≥15 pts in period 2
  SELECT
    game_id,
    team_market,
    player_id,
    SUM(COALESCE(points_scored,0)) AS pts_p2
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018        -- seasons of interest
    AND period = 2                          -- second period only
    AND player_id IS NOT NULL
  GROUP BY game_id, team_market, player_id
  HAVING pts_p2 >= 15
),

market_player_counts AS (        -- # distinct players per market
  SELECT
    team_market   AS market,
    COUNT(DISTINCT player_id) AS num_distinct_players
  FROM player_second_period
  GROUP BY market
),

top_markets AS (                 -- keep the five biggest
  SELECT market
  FROM market_player_counts
  ORDER BY num_distinct_players DESC, market
  LIMIT 5
),

tournament_games AS (            -- NCAA tournament games 2010‑2018
  SELECT *
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
)

-- -------------  FINAL SELECT  --------------------------
-- create a row for the market whether it won or lost
SELECT
  tg.season,
  tg.round,
  tg.game_date,
  tg.day,
  'win'                             AS label,
  tg.win_seed                       AS seed,
  tg.win_market                     AS market,
  tg.win_name                       AS name,
  tg.win_alias                      AS alias,
  tg.win_school_ncaa                AS school_ncaa,
  tg.win_code_ncaa                  AS code_ncaa,
  tg.win_kaggle_team_id             AS kaggle_team_id,
  tg.win_pts                        AS pts,
  tg.lose_seed                      AS opponent_seed,
  tg.lose_market                    AS opponent_market,
  tg.lose_name                      AS opponent_name,
  tg.lose_alias                     AS opponent_alias,
  tg.lose_school_ncaa               AS opponent_school_ncaa,
  tg.lose_code_ncaa                 AS opponent_code_ncaa,
  tg.lose_kaggle_team_id            AS opponent_kaggle_team_id,
  tg.lose_pts                       AS opponent_pts,
  tg.num_ot
FROM tournament_games tg
JOIN top_markets tm
  ON tg.win_market = tm.market

UNION ALL

SELECT
  tg.season,
  tg.round,
  tg.game_date,
  tg.day,
  'loss'                            AS label,
  tg.lose_seed                      AS seed,
  tg.lose_market                    AS market,
  tg.lose_name                      AS name,
  tg.lose_alias                     AS alias,
  tg.lose_school_ncaa               AS school_ncaa,
  tg.lose_code_ncaa                 AS code_ncaa,
  tg.lose_kaggle_team_id            AS kaggle_team_id,
  tg.lose_pts                       AS pts,
  tg.win_seed                       AS opponent_seed,
  tg.win_market                     AS opponent_market,
  tg.win_name                       AS opponent_name,
  tg.win_alias                      AS opponent_alias,
  tg.win_school_ncaa                AS opponent_school_ncaa,
  tg.win_code_ncaa                  AS opponent_code_ncaa,
  tg.win_kaggle_team_id             AS opponent_kaggle_team_id,
  tg.win_pts                        AS opponent_pts,
  tg.num_ot
FROM tournament_games tg
JOIN top_markets tm
  ON tg.lose_market = tm.market

ORDER BY season, round, game_date, market, label;