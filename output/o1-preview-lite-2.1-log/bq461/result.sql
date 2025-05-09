WITH game_teams AS (
  SELECT
    gs.game_id,
    tm_h.alias AS home_team,
    gs.h_id AS home_team_id,
    tm_a.alias AS away_team,
    gs.a_id AS away_team_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr` gs
  JOIN `bigquery-public-data.ncaa_basketball.mbb_teams` tm_h ON gs.h_id = tm_h.id
  JOIN `bigquery-public-data.ncaa_basketball.mbb_teams` tm_a ON gs.a_id = tm_a.id
  WHERE gs.game_id = '95cda731-b593-42cd-8573-621a3d1369dc'
),
scoring_plays AS (
  SELECT
    p.elapsed_time_sec,
    p.period,
    p.game_clock,
    p.team_id,
    tm.alias AS scoring_team,
    p.points_scored,
    p.event_description
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` p
  JOIN `bigquery-public-data.ncaa_basketball.mbb_teams` tm ON p.team_id = tm.id
  WHERE p.game_id = '95cda731-b593-42cd-8573-621a3d1369dc' AND p.points_scored IS NOT NULL
),
cumulative_scores AS (
  SELECT
    s.*,
    SUM(CASE WHEN s.team_id = gt.home_team_id THEN s.points_scored ELSE 0 END)
      OVER (ORDER BY s.elapsed_time_sec) AS home_team_score,
    SUM(CASE WHEN s.team_id = gt.away_team_id THEN s.points_scored ELSE 0 END)
      OVER (ORDER BY s.elapsed_time_sec) AS away_team_score
  FROM scoring_plays s
  CROSS JOIN game_teams gt
)
SELECT
  period,
  game_clock,
  CONCAT(gt.home_team, ' ', home_team_score, ' - ', gt.away_team, ' ', away_team_score) AS team_scores,
  scoring_team,
  event_description AS description
FROM cumulative_scores s
CROSS JOIN game_teams gt
ORDER BY s.elapsed_time_sec;