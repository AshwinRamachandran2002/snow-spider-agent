-- Chronological list of every scoring play in the 2014 season game
-- with the Wildcats at home and the Fighting Irish away
WITH game AS (
  -- Identify the unique game_id (there should only be one)
  SELECT
    DISTINCT game_id,
    home_id        AS wildcats_id,
    away_id        AS irish_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season = 2014
    AND home_name  = 'Wildcats'
    AND away_name  = 'Fighting Irish'
  LIMIT 1
),
scoring_plays AS (
  -- Pull only plays that put points on the board
  SELECT
    p.game_id,
    p.period,
    p.game_clock,
    p.elapsed_time_sec,
    p.points_scored,
    p.team_id,
    p.event_description,
    CASE
      WHEN p.team_id = g.wildcats_id THEN 'Wildcats'
      WHEN p.team_id = g.irish_id    THEN 'Fighting Irish'
    END AS scoring_team
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` AS p
  JOIN game AS g
    ON p.game_id = g.game_id
  WHERE p.points_scored IS NOT NULL
    AND p.points_scored > 0
),
cume AS (
  -- Running score for each side
  SELECT
    period,
    game_clock,
    elapsed_time_sec,
    scoring_team,
    event_description,
    SUM(CASE WHEN scoring_team = 'Wildcats'       THEN points_scored ELSE 0 END)
      OVER (ORDER BY elapsed_time_sec ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      AS wildcats_score,
    SUM(CASE WHEN scoring_team = 'Fighting Irish' THEN points_scored ELSE 0 END)
      OVER (ORDER BY elapsed_time_sec ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      AS fighting_irish_score
  FROM scoring_plays
)
SELECT
  -- period prefix makes clock values unique/clear
  CONCAT('P', period, ' ', game_clock)  AS game_clock,
  wildcats_score                        AS wildcats_cumulative_pts,
  fighting_irish_score                  AS fighting_irish_cumulative_pts,
  scoring_team,
  event_description
FROM cume
ORDER BY elapsed_time_sec;