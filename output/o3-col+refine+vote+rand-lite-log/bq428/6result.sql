-- 1) Identify players who scored ≥15 pts in the 2nd period of any game (2010-2018)
-- 2) Count how many DISTINCT such players each team_market has and keep the TOP-5
-- 3) Return every historical-tournament game (2010-2018) in which any of those
--    five markets appeared (either as winner or loser)

WITH player_second_period AS (
  SELECT
    team_market,
    player_id,
    SUM(CAST(points_scored AS INT64)) AS pts_2nd_period
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2                      -- second half
    AND points_scored IS NOT NULL
  GROUP BY team_market, player_id
),
top_markets AS (
  SELECT
    team_market AS market,
    COUNT(DISTINCT player_id) AS distinct_players_15pts
  FROM player_second_period
  WHERE pts_2nd_period >= 15            -- threshold
  GROUP BY team_market
  ORDER BY distinct_players_15pts DESC
  LIMIT 5                               -- TOP-5 markets
)

SELECT DISTINCT
  htg.season,
  htg.round,
  htg.game_date,
  htg.day,
  htg.win_seed,
  htg.win_market,
  htg.win_name,
  htg.win_pts,
  htg.lose_seed,
  htg.lose_market,
  htg.lose_name,
  htg.lose_pts,
  htg.num_ot
FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` AS htg
JOIN top_markets tm
  ON htg.win_market  = tm.market
  OR htg.lose_market = tm.market
WHERE htg.season BETWEEN 2010 AND 2018
ORDER BY htg.season, htg.round, htg.game_date;