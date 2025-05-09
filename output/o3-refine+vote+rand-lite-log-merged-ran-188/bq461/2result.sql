-- Chronological summary of every scoring play in the 2014 season game
-- where Kentucky (Wildcats) hosted Notre Dame (Fighting Irish).
WITH target_game AS (      -- 1. Locate the single game_id of interest
  SELECT DISTINCT game_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season       = 2014
    AND home_market  = 'Kentucky'
    AND away_market  = 'Notre Dame'
),
scoring AS (               -- 2. Keep only scoring events from that game
  SELECT
    game_id,
    period,
    game_clock,
    elapsed_time_sec,
    event_id,
    team_market,
    points_scored,
    event_description
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE game_id IN (SELECT game_id FROM target_game)
    AND points_scored IS NOT NULL
),
running AS (               -- 3. Build running totals for each team
  SELECT
    game_clock,
    elapsed_time_sec,
    event_id,
    -- cumulative points for the home Wildcats (Kentucky)
    SUM(CASE WHEN team_market = 'Kentucky'   THEN points_scored ELSE 0 END)
      OVER(ORDER BY elapsed_time_sec, event_id) AS wildcats_score,
    -- cumulative points for the away Fighting Irish (Notre Dame)
    SUM(CASE WHEN team_market = 'Notre Dame' THEN points_scored ELSE 0 END)
      OVER(ORDER BY elapsed_time_sec, event_id) AS fighting_irish_score,
    team_market  AS scoring_team,
    event_description
  FROM scoring
)
SELECT
  game_clock,
  wildcats_score,
  fighting_irish_score,
  scoring_team,
  event_description
FROM running
ORDER BY elapsed_time_sec, event_id;