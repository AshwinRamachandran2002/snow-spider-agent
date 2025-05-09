-- Chronological scoring summary for the 2014-season game
-- where the Wildcats were home and the Fighting Irish were away
WITH game AS (
  SELECT game_id
  FROM   `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE  season  = 2014
    AND  h_name  = 'Wildcats'       -- home = Kentucky
    AND  a_name  = 'Fighting Irish' -- away = Notre Dame
  LIMIT  1                           -- => 95cda731-b593-42cd-8573-621a3d1369dc
),
plays AS (   -- keep only “made” shots for that game
  SELECT elapsed_time_sec,
         game_clock,
         team_name,
         event_description,
         CASE
           WHEN REGEXP_CONTAINS(LOWER(event_description), r'free throw')
                THEN 1
           WHEN REGEXP_CONTAINS(LOWER(event_description), r'(three|3[- ]?pt)')
                THEN 3
           ELSE 2
         END AS pts_scored
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE  game_id = (SELECT game_id FROM game)
    AND  LOWER(event_description) LIKE '% makes %'
),
running AS (   -- build running totals
  SELECT elapsed_time_sec,
         game_clock,
         team_name                    AS scoring_team,
         event_description,
         SUM(CASE WHEN team_name = 'Wildcats'       THEN pts_scored END)
           OVER (ORDER BY elapsed_time_sec) AS wildcats_pts,
         SUM(CASE WHEN team_name = 'Fighting Irish' THEN pts_scored END)
           OVER (ORDER BY elapsed_time_sec) AS irish_pts
  FROM plays
)
SELECT game_clock,
       FORMAT('%d-%d', wildcats_pts, irish_pts) AS score_wildcats_irish,
       scoring_team,
       event_description
FROM   running
ORDER  BY elapsed_time_sec;