-- chronological list of every scoring play in the 2014 season game
-- where the home team was the Wildcats and the away team was the Fighting Irish
WITH chosen_game AS (
  SELECT DISTINCT game_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season = 2014
    AND home_name = 'Wildcats'
    AND away_name = 'Fighting Irish'
  LIMIT 1            -- only one game should satisfy these criteria
),
scoring_events AS (
  SELECT
    p.elapsed_time_sec,
    p.game_clock,
    p.team_name           AS scoring_team,       -- 'Wildcats' or 'Fighting Irish'
    p.event_description,
    COALESCE(p.points_scored,0) AS points_scored,
    -- points attributed to each side for running totals
    CASE WHEN p.team_name = 'Wildcats'        THEN COALESCE(p.points_scored,0) ELSE 0 END AS pts_wildcats,
    CASE WHEN p.team_name = 'Fighting Irish'  THEN COALESCE(p.points_scored,0) ELSE 0 END AS pts_irish
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`  p
  JOIN chosen_game g
    ON p.game_id = g.game_id
  WHERE COALESCE(p.points_scored,0) > 0        -- keep only scoring plays
),
running_score AS (
  SELECT
    elapsed_time_sec,
    game_clock,
    scoring_team,
    event_description,
    -- running totals for the score board
    SUM(pts_wildcats) OVER (ORDER BY elapsed_time_sec
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS wildcats_score,
    SUM(pts_irish)     OVER (ORDER BY elapsed_time_sec
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fighting_irish_score
  FROM scoring_events
)
SELECT
  game_clock,
  wildcats_score      AS cumulative_wildcats_pts,
  fighting_irish_score AS cumulative_fighting_irish_pts,
  scoring_team,
  event_description
FROM running_score
ORDER BY elapsed_time_sec;