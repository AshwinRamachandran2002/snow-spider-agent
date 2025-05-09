WITH player_scores AS (
  SELECT 
    LOWER(TRIM(team_market)) AS team_market,
    player_id,
    game_id,
    SUM(points_scored) AS total_points
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE 
    season BETWEEN 2010 AND 2018
    AND period = 2
    AND player_id IS NOT NULL
    AND points_scored IS NOT NULL
    AND team_market IS NOT NULL
  GROUP BY team_market, player_id, game_id
  HAVING total_points >= 15
),
top_teams AS (
  SELECT team_market, COUNT(DISTINCT player_id) AS num_players
  FROM player_scores
  GROUP BY team_market
  ORDER BY num_players DESC
  LIMIT 5
)
SELECT
  tg.season,
  tg.game_date,
  CASE 
    WHEN LOWER(TRIM(tg.win_market)) IN (SELECT team_market FROM top_teams) THEN tg.win_market
    ELSE tg.lose_market
  END AS team_market,
  CASE 
    WHEN LOWER(TRIM(tg.win_market)) IN (SELECT team_market FROM top_teams) THEN tg.win_name
    ELSE tg.lose_name
  END AS team_name,
  CASE 
    WHEN LOWER(TRIM(tg.win_market)) IN (SELECT team_market FROM top_teams) THEN tg.lose_market
    ELSE tg.win_market
  END AS opponent_market,
  CASE 
    WHEN LOWER(TRIM(tg.win_market)) IN (SELECT team_market FROM top_teams) THEN tg.lose_name
    ELSE tg.win_name
  END AS opponent_name,
  CASE 
    WHEN LOWER(TRIM(tg.win_market)) IN (SELECT team_market FROM top_teams) THEN tg.win_pts
    ELSE tg.lose_pts
  END AS win_pts,
  CASE 
    WHEN LOWER(TRIM(tg.win_market)) IN (SELECT team_market FROM top_teams) THEN tg.lose_pts
    ELSE tg.win_pts
  END AS lose_pts,
  COALESCE(tg.num_ot, 0) AS num_ot
FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` tg
WHERE 
  tg.season BETWEEN 2010 AND 2018
  AND (
    LOWER(TRIM(tg.win_market)) IN (SELECT team_market FROM top_teams)
    OR
    LOWER(TRIM(tg.lose_market)) IN (SELECT team_market FROM top_teams)
  )
  AND tg.win_market IS NOT NULL
  AND tg.lose_market IS NOT NULL;