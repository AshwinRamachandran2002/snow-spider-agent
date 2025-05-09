-- Chronological list of every scoring play for the 2014 season game
-- in which the Wildcats were the HOME team and the Fighting Irish were
-- the AWAY team.  For each play we return the game clock, the running
-- score for both schools, the team that scored, and the play‑by‑play
-- description.

WITH target_game AS (               -- identify the one game we need
  SELECT DISTINCT
         game_id,
         home_id AS wildcats_id,
         away_id AS irish_id
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE  season = 2014
    AND  LOWER(home_name)  = 'wildcats'
    AND  LOWER(away_name) LIKE '%fighting irish%'
),

scoring_events AS (                 -- pull only the rows where points were scored
  SELECT p.*,
         g.wildcats_id,
         g.irish_id
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` p
  JOIN   target_game g
         ON p.game_id = g.game_id
  WHERE  p.points_scored IS NOT NULL          -- scoring plays only
)

SELECT
  period,
  game_clock,
  -- running total for Wildcats
  SUM(CASE WHEN team_id = wildcats_id THEN points_scored ELSE 0 END)
      OVER (ORDER BY elapsed_time_sec, event_id) AS wildcats_score,
  -- running total for Fighting Irish
  SUM(CASE WHEN team_id = irish_id THEN points_scored ELSE 0 END)
      OVER (ORDER BY elapsed_time_sec, event_id) AS irish_score,
  CASE WHEN team_id = wildcats_id THEN 'Wildcats'
       ELSE 'Fighting Irish' END              AS scoring_team,
  event_description
FROM   scoring_events
ORDER  BY elapsed_time_sec, event_id;