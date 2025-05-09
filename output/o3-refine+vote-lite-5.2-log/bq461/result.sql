-- Chronological list of every scoring play from the 2014 season game
-- in which the home team were the Wildcats and the away team were the
-- Notre Dame Fighting Irish.

WITH selected_game AS (   -- find the unique 2014 game that matches the description
  SELECT
    DISTINCT game_id,
    home_id  AS wildcats_id,
    away_id  AS irish_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season = 2014
    AND home_name  = 'Wildcats'        -- team nickname
    AND away_name  = 'Fighting Irish'  -- team nickname
    AND away_market = 'Notre Dame'     -- school
  LIMIT 1                               -- there should be only one such game
),

plays AS (   -- keep only scoring events for that game
  SELECT
    p.game_id,
    p.event_id,
    p.elapsed_time_sec,
    p.game_clock,
    p.team_id,
    p.points_scored,
    p.event_description
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` AS p
  JOIN selected_game AS g
    ON p.game_id = g.game_id
  WHERE p.points_scored IS NOT NULL
    AND p.points_scored > 0             -- scoring plays only
)

SELECT
  game_clock,                                                -- time left in period
  wildcats_score,                                            -- running total
  fighting_irish_score,                                      -- running total
  CASE WHEN team_id = wildcats_id
       THEN 'Wildcats'
       ELSE 'Fighting Irish'
  END          AS team_scored,
  event_description
FROM (
  SELECT
    game_clock,
    event_description,
    team_id,
    event_id,
    elapsed_time_sec,
    -- cumulative points for each side up to and including this play
    SUM(CASE WHEN team_id = wildcats_id THEN points_scored ELSE 0 END)
        OVER (ORDER BY elapsed_time_sec, event_id) AS wildcats_score,
    SUM(CASE WHEN team_id = irish_id    THEN points_scored ELSE 0 END)
        OVER (ORDER BY elapsed_time_sec, event_id) AS fighting_irish_score,
    wildcats_id,
    irish_id
  FROM plays
  CROSS JOIN selected_game
)
ORDER BY elapsed_time_sec, event_id;    -- chronological order