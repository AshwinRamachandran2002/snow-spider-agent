-- Chronological list of every scoring play in the 2014 season game
-- where the home team’s name is “Wildcats” and the away team’s name
-- is “Fighting Irish”.
--
-- Output columns:
--   game_clock          – “P<period> <clock>” (time left in period)
--   wildcats_score      – running total for the Wildcats (home)
--   fightingirish_score – running total for the Fighting Irish (away)
--   scoring_team        – which team scored on the play
--   event_description   – Sportradar description of the play
WITH picked_game AS (        -- identify the single game we care about
  SELECT
    game_id,
    home_id,
    away_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season = 2014
    AND home_name = 'Wildcats'
    AND away_name = 'Fighting Irish'
  -- if (unlikely) more than one such game exists, keep the first chronologically
  ORDER BY scheduled_date
  LIMIT 1
),
scoring_events AS (          -- keep only plays where points were scored
  SELECT
    p.game_id,
    p.period,
    p.game_clock,
    p.elapsed_time_sec,
    p.event_id,
    p.event_description,
    p.points_scored,
    p.team_id,
    g.home_id,
    g.away_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` p
  JOIN picked_game g
    ON p.game_id = g.game_id
  WHERE p.points_scored IS NOT NULL
    AND p.points_scored > 0
)
SELECT
  CONCAT('P', CAST(period AS STRING), ' ', game_clock)         AS game_clock,
  wildcats_score,
  fightingirish_score,
  scoring_team,
  event_description
FROM (
  SELECT
    *,
    SUM(CASE WHEN team_id = home_id THEN points_scored ELSE 0 END)
        OVER (ORDER BY elapsed_time_sec, event_id
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS wildcats_score,
    SUM(CASE WHEN team_id = away_id THEN points_scored ELSE 0 END)
        OVER (ORDER BY elapsed_time_sec, event_id
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fightingirish_score,
    CASE
      WHEN team_id = home_id THEN 'Wildcats'
      WHEN team_id = away_id THEN 'Fighting Irish'
      ELSE 'Unknown'
    END AS scoring_team
  FROM scoring_events
)
ORDER BY elapsed_time_sec, event_id;