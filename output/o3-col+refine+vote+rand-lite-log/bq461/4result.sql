-- Chronological scoring summary for the 2014 season game
-- with the Wildcats as the home team and the Fighting Irish as the away team
WITH target_game AS (
  SELECT DISTINCT game_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season = 2014
    AND home_name = 'Wildcats'
    AND away_name = 'Fighting Irish'
),
scoring_plays AS (
  SELECT
    period,
    game_clock,
    elapsed_time_sec,
    team_name,
    points_scored,
    event_description
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE game_id IN (SELECT game_id FROM target_game)
    AND points_scored IS NOT NULL
)
SELECT
  CONCAT('P', period, ' ', game_clock)              AS game_clock,
  wildcats_running_total                            AS wildcats_pts,
  irish_running_total                               AS irish_pts,
  team_name                                         AS scoring_team,
  event_description
FROM (
  SELECT
    period,
    game_clock,
    elapsed_time_sec,
    team_name,
    points_scored,
    event_description,
    SUM(CASE WHEN team_name = 'Wildcats'       THEN points_scored ELSE 0 END)
      OVER (ORDER BY elapsed_time_sec
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS wildcats_running_total,
    SUM(CASE WHEN team_name = 'Fighting Irish' THEN points_scored ELSE 0 END)
      OVER (ORDER BY elapsed_time_sec
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS irish_running_total
  FROM scoring_plays
)
ORDER BY elapsed_time_sec;