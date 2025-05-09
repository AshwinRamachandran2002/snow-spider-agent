WITH plays AS (
  SELECT
    elapsed_time_sec,
    game_clock,
    team_market,
    SAFE_CAST(points_scored AS INT64) AS pts,
    event_description,
    event_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE game_id = '95cda731-b593-42cd-8573-621a3d1369dc'
    AND points_scored > 0
),
running_totals AS (
  SELECT
    *,
    SUM(IF(team_market = 'Kentucky', pts, 0))
      OVER (ORDER BY elapsed_time_sec, event_id) AS wildcats_score,
    SUM(IF(team_market = 'Notre Dame', pts, 0))
      OVER (ORDER BY elapsed_time_sec, event_id) AS fighting_irish_score
  FROM plays
)
SELECT
  game_clock,
  wildcats_score,
  fighting_irish_score,
  team_market AS scoring_team,
  event_description AS description
FROM running_totals
ORDER BY elapsed_time_sec, event_id;