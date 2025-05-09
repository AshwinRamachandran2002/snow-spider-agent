WITH team_ids AS (
  SELECT
    '2267a1f4-68f6-418b-aaf6-2aa0c4b291f1' AS wildcats_id,       -- Kentucky Wildcats
    '80962f09-8821-48b6-8cf0-0cf0eea56aa8' AS fighting_irish_id  -- Notre Dame Fighting Irish
),
game_between_teams AS (
  SELECT game_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
    season = 2014
    AND team_id IN (
      SELECT wildcats_id FROM team_ids
      UNION ALL
      SELECT fighting_irish_id FROM team_ids
    )
  GROUP BY game_id
  HAVING COUNT(DISTINCT team_id) = 2
),
scoring_events AS (
  SELECT
    period,
    game_clock,
    elapsed_time_sec,
    team_name,
    team_id,
    points_scored,
    event_description
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
    game_id IN (SELECT game_id FROM game_between_teams)
    AND points_scored > 0
),
cumulative_scores AS (
  SELECT
    se.*,
    SUM(CASE WHEN se.team_id = (SELECT wildcats_id FROM team_ids) THEN se.points_scored ELSE 0 END) OVER (
      ORDER BY se.period, se.elapsed_time_sec
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Wildcats_score,
    SUM(CASE WHEN se.team_id = (SELECT fighting_irish_id FROM team_ids) THEN se.points_scored ELSE 0 END) OVER (
      ORDER BY se.period, se.elapsed_time_sec
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Fighting_Irish_score
  FROM scoring_events se
)
SELECT
  period,
  game_clock,
  CONCAT(CAST(Wildcats_score AS INT64), '-', CAST(Fighting_Irish_score AS INT64)) AS Team_scores,
  team_name AS Scoring_team,
  event_description AS Description
FROM cumulative_scores
ORDER BY period, elapsed_time_sec