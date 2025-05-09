-- Chronological list of every scoring play (with running total) in the
-- 2014-season game where the home team was the Kentucky Wildcats and
-- the away team was the Notre Dame Fighting Irish.

WITH chosen_game AS (
  -- Identify the single 2014 contest that matches the description and
  -- keep the two participating team_ids for later use.
  SELECT DISTINCT
         game_id,
         home_id AS wildcats_team_id,
         away_id AS irish_team_id
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE  season        = 2014
    AND  home_name     = 'Wildcats'
    AND  away_name     = 'Fighting Irish'
),

plays AS (
  -- Pull just the scoring events (points_scored IS NOT NULL) for that game.
  SELECT
    p.event_id,
    p.elapsed_time_sec,
    p.game_clock,
    p.team_id,
    p.points_scored,
    p.event_description,
    g.wildcats_team_id,
    g.irish_team_id
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` AS p
  JOIN   chosen_game                                   AS g
    ON   p.game_id = g.game_id
  WHERE  p.points_scored IS NOT NULL
),

running_totals AS (
  -- Add running totals for both sides.
  SELECT
    elapsed_time_sec,
    game_clock,
    team_id,
    points_scored,
    event_description,
    SUM(CASE WHEN team_id = wildcats_team_id
             THEN points_scored ELSE 0 END)
        OVER (ORDER BY elapsed_time_sec) AS wildcats_pts,
    SUM(CASE WHEN team_id = irish_team_id
             THEN points_scored ELSE 0 END)
        OVER (ORDER BY elapsed_time_sec) AS irish_pts
  FROM plays
)

SELECT
  game_clock,
  CONCAT(CAST(wildcats_pts AS STRING), '-', CAST(irish_pts AS STRING))
      AS score_wildcats_irish,
  CASE WHEN team_id = (SELECT wildcats_team_id FROM chosen_game)
       THEN 'Wildcats' ELSE 'Fighting Irish' END               AS scoring_team,
  points_scored,
  event_description
FROM   running_totals
ORDER  BY elapsed_time_sec;