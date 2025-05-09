/* Chronological scoring summary for the 2014 season game in which the home team’s
   nickname is “Wildcats” and the away team’s nickname is “Fighting Irish”          */
WITH chosen_game AS (     -- identify the single 2014 game that meets the criteria
  SELECT
    game_id,
    home_id  AS wildcats_id,
    away_id  AS irish_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season = 2014
    AND home_name = 'Wildcats'
    AND away_name = 'Fighting Irish'
  LIMIT 1                  -- there should be only one such contest
),
scoring_events AS (       -- pull every play that produced points in that game
  SELECT
    p.game_id,
    p.event_id,
    p.period,
    p.elapsed_time_sec,
    p.game_clock,
    p.team_id,
    CAST(p.points_scored AS INT64) AS points_scored,
    p.event_description,
    g.wildcats_id,
    g.irish_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` AS p
  JOIN chosen_game AS g
    ON p.game_id = g.game_id
  WHERE p.points_scored IS NOT NULL
    AND p.points_scored > 0            -- points_scored is 1, 2, or 3 on scoring plays
),
running_totals AS (       -- keep a running scoreboard as the game progresses
  SELECT
    event_id,
    period,
    elapsed_time_sec,
    game_clock,
    team_id,
    event_description,
    SUM(IF(team_id = wildcats_id, points_scored, 0))
      OVER (ORDER BY elapsed_time_sec, event_id) AS wildcats_score,
    SUM(IF(team_id = irish_id,    points_scored, 0))
      OVER (ORDER BY elapsed_time_sec, event_id) AS fighting_irish_score,
    wildcats_id,
    irish_id
  FROM scoring_events
)
SELECT
  period,
  game_clock,
  wildcats_score      AS wildcats_cumulative,
  fighting_irish_score AS fighting_irish_cumulative,
  CASE WHEN team_id = wildcats_id THEN 'Wildcats'
       ELSE 'Fighting Irish' END       AS scoring_team,
  event_description
FROM running_totals
ORDER BY elapsed_time_sec, event_id;