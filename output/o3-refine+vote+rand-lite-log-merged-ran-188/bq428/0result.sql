-- Top-5 markets by number of distinct players with ≥15 points
-- in 2nd period (2010-2018) and every NCAA-tournament game
-- they played in the same span (win or loss)
WITH players15 AS (
  SELECT
    player_id,
    team_market
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2
  GROUP BY game_id, player_id, team_market
  HAVING SUM(points_scored) >= 15
),
top5 AS (
  SELECT
    team_market,
    COUNT(DISTINCT player_id) AS cnt_players
  FROM players15
  GROUP BY team_market
  ORDER BY cnt_players DESC
  LIMIT 5
),
hist AS (
  -- winning side
  SELECT
    season,
    round,
    game_date,
    day,
    win_market   AS team_market,
    win_name     AS team_name,
    win_seed     AS seed,
    win_pts      AS pts,
    lose_market  AS opp_market,
    lose_name    AS opp_name,
    lose_seed    AS opp_seed,
    lose_pts     AS opp_pts,
    num_ot,
    'win'        AS result
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
  UNION ALL
  -- losing side
  SELECT
    season,
    round,
    game_date,
    day,
    lose_market  AS team_market,
    lose_name    AS team_name,
    lose_seed    AS seed,
    lose_pts     AS pts,
    win_market   AS opp_market,
    win_name     AS opp_name,
    win_seed     AS opp_seed,
    win_pts      AS opp_pts,
    num_ot,
    'loss'       AS result
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
)
SELECT
  h.season,
  h.round,
  h.game_date,
  h.day,
  h.team_market,
  h.team_name,
  h.seed,
  h.pts,
  h.opp_market,
  h.opp_name,
  h.opp_seed,
  h.opp_pts,
  h.num_ot,
  h.result
FROM hist AS h
JOIN top5 AS t
ON h.team_market = t.team_market
ORDER BY h.team_market, h.season, h.game_date;