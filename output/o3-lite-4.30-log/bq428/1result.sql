WITH player_second_period AS (
  SELECT
    season,
    game_id,
    player_id,
    team_market,
    SUM(points_scored) AS period2_pts
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2
    AND points_scored IS NOT NULL
  GROUP BY season, game_id, player_id, team_market
  HAVING period2_pts >= 15
),
top_markets AS (
  SELECT team_market AS market
  FROM (
    SELECT
      team_market,
      COUNT(DISTINCT player_id) AS num_players
    FROM player_second_period
    GROUP BY team_market
    ORDER BY num_players DESC, team_market
    LIMIT 5
  )
)
SELECT DISTINCT
  t.season,
  t.`round`,
  t.game_date,
  t.win_market,
  t.win_name,
  t.win_seed,
  t.win_pts,
  t.lose_market,
  t.lose_name,
  t.lose_seed,
  t.lose_pts
FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` AS t
JOIN top_markets AS m
  ON t.win_market = m.market
  OR t.lose_market = m.market
WHERE t.season BETWEEN 2010 AND 2018
ORDER BY t.season, t.game_date, t.win_market, t.lose_market;