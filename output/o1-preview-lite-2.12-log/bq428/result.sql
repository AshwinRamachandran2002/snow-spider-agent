WITH player_game_points AS (
  SELECT
    game_id,
    season,
    team_id,
    team_market,
    player_id,
    SUM(points_scored) AS total_points
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE period = 2
    AND season BETWEEN 2010 AND 2018
  GROUP BY game_id, season, team_id, team_market, player_id
),
players_with_15_in_game AS (
  SELECT DISTINCT
    team_id,
    team_market,
    player_id
  FROM player_game_points
  WHERE total_points >= 15
),
top_teams AS (
  SELECT
    team_market,
    team_id,
    COUNT(DISTINCT player_id) AS num_players
  FROM players_with_15_in_game
  GROUP BY team_market, team_id
  ORDER BY num_players DESC
  LIMIT 5
),
team_kaggle_ids AS (
  SELECT
    tt.team_id,
    tt.team_market,
    mt.kaggle_team_id
  FROM top_teams tt
  JOIN `bigquery-public-data.ncaa_basketball.mbb_teams` mt
    ON tt.team_id = mt.id
  WHERE mt.kaggle_team_id IS NOT NULL
),
tournament_games AS (
  SELECT
    htg.*
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` htg
  WHERE htg.season BETWEEN 2010 AND 2018
    AND (
      htg.win_kaggle_team_id IN (SELECT kaggle_team_id FROM team_kaggle_ids)
      OR htg.lose_kaggle_team_id IN (SELECT kaggle_team_id FROM team_kaggle_ids)
    )
)
SELECT
  htg.season,
  htg.game_date,
  CASE
    WHEN htg.win_kaggle_team_id IN (SELECT kaggle_team_id FROM team_kaggle_ids) THEN htg.win_market
    ELSE htg.lose_market
  END AS team_market,
  CASE
    WHEN htg.win_kaggle_team_id IN (SELECT kaggle_team_id FROM team_kaggle_ids) THEN htg.win_name
    ELSE htg.lose_name
  END AS team_name,
  CASE
    WHEN htg.win_kaggle_team_id IN (SELECT kaggle_team_id FROM team_kaggle_ids) THEN htg.lose_market
    ELSE htg.win_market
  END AS opponent_market,
  CASE
    WHEN htg.win_kaggle_team_id IN (SELECT kaggle_team_id FROM team_kaggle_ids) THEN htg.lose_name
    ELSE htg.win_name
  END AS opponent_name,
  CAST(
    CASE
      WHEN htg.win_kaggle_team_id IN (SELECT kaggle_team_id FROM team_kaggle_ids) THEN htg.win_pts
      ELSE htg.lose_pts
    END AS INT64
  ) AS win_pts,
  CAST(
    CASE
      WHEN htg.win_kaggle_team_id IN (SELECT kaggle_team_id FROM team_kaggle_ids) THEN htg.lose_pts
      ELSE htg.win_pts
    END AS INT64
  ) AS lose_pts,
  COALESCE(htg.num_ot, 0) AS num_ot
FROM tournament_games htg
ORDER BY htg.season, htg.game_date;