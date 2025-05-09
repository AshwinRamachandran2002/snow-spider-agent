-- Description:  Chronological list of every scoring play in the 2014-season game
--               where the home team’s on-court name is “Wildcats” and the away
--               team’s on-court name is “Fighting Irish”.  For each play show
--               the period, game-clock, running scores for both sides,
--               the team that scored, and a short description of the play.

WITH target_game AS (        -- 1.  Find the one game that matches the criteria
  SELECT
    game_id,
    h_market AS wildcats_market,        -- Kentucky
    a_market AS irish_market            -- Notre Dame
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season = 2014
    AND LOWER(h_name) = 'wildcats'
    AND LOWER(a_name) = 'fighting irish'
),

scoring_plays AS (           -- 2.  Pull the play-by-play rows that scored points
  SELECT
    p.elapsed_time_sec,
    p.period,
    p.game_clock,
    p.team_market                    AS scoring_team,
    p.points_scored                  AS points,
    -- running totals for each school
    SUM(CASE WHEN p.team_market = g.wildcats_market THEN p.points_scored END)
        OVER (ORDER BY p.elapsed_time_sec)          AS wildcats_score,
    SUM(CASE WHEN p.team_market = g.irish_market   THEN p.points_scored END)
        OVER (ORDER BY p.elapsed_time_sec)          AS irish_score,
    p.event_description
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` AS p
  JOIN target_game AS g
    ON p.game_id = g.game_id
  WHERE p.points_scored IS NOT NULL                 -- keep only scoring events
)

-- 3.  Present the scoring log in game order
SELECT
  period,
  game_clock,
  wildcats_score,
  irish_score,
  scoring_team,
  event_description
FROM scoring_plays
ORDER BY elapsed_time_sec;