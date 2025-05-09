-- Top‑5 markets by number of distinct players with ≥15 period‑2 points (2010‑2018),
-- and every NCAA tournament game (2010‑2018) those markets played in.
WITH high_scorers AS (
  -- player‑game rows with 15+ points in period‑2
  SELECT
    team_market,
    player_id
  FROM (
    SELECT
      team_market,
      player_id,
      game_id,
      SUM(points_scored) AS period2_pts
    FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
    WHERE season BETWEEN 2010 AND 2018
      AND period = 2
      AND points_scored IS NOT NULL
    GROUP BY team_market, player_id, game_id
    HAVING period2_pts >= 15
  )
  GROUP BY team_market, player_id
),
market_counts AS (
  SELECT
    team_market,
    COUNT(*) AS num_distinct_players,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rk
  FROM high_scorers
  GROUP BY team_market
),
top_markets AS (
  SELECT
    team_market,
    num_distinct_players
  FROM market_counts
  WHERE rk <= 5
)
SELECT
  tm.team_market,
  tm.num_distinct_players,          -- count of distinct high‑scoring players
  htg.season,
  htg.game_date,
  htg.round,
  CASE
    WHEN htg.win_market = tm.team_market THEN 'win' ELSE 'loss'
  END AS label,
  CASE
    WHEN htg.win_market = tm.team_market THEN htg.win_seed ELSE htg.lose_seed
  END AS seed,
  CASE
    WHEN htg.win_market = tm.team_market THEN htg.win_pts ELSE htg.lose_pts
  END AS team_pts,
  CASE
    WHEN htg.win_market = tm.team_market THEN htg.lose_market ELSE htg.win_market
  END AS opponent_market,
  CASE
    WHEN htg.win_market = tm.team_market THEN htg.lose_pts ELSE htg.win_pts
  END AS opponent_pts
FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` AS htg
JOIN top_markets AS tm
  ON htg.win_market = tm.team_market
  OR htg.lose_market = tm.team_market
WHERE htg.season BETWEEN 2010 AND 2018
ORDER BY tm.team_market, htg.season, htg.round;