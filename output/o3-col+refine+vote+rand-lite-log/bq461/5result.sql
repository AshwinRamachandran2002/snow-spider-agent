/*  Chronological scoring summary  
    Game: 2014 season – home Wildcats vs. away Fighting Irish                */

-- 1)  Identify the single 2014-season game that matches the criteria
WITH target_game AS (
  SELECT
    game_id,
    h_market AS wildcats_school,      -- e.g. Kentucky
    a_market AS irish_school          -- Notre Dame
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season = 2014
    AND LOWER(h_name)   = 'wildcats'          -- home team’s *name*
    AND LOWER(a_market) = 'notre dame'        -- away team’s school
    AND LOWER(a_name)   = 'fighting irish'    -- away team’s *name*
  LIMIT 1
),

-- 2)  Pull every scoring play from the play-by-play for that game
scoring_events AS (
  SELECT
    pbp.elapsed_time_sec,
    pbp.game_clock,
    pbp.period,
    pbp.team_market,
    SAFE_CAST(pbp.points_scored AS INT64) AS pts,
    pbp.event_description,
    tg.wildcats_school,
    tg.irish_school
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` AS pbp
  JOIN target_game AS tg
    ON pbp.game_id = tg.game_id
  WHERE pbp.points_scored IS NOT NULL          -- keep only scoring plays
)

-- 3)  Build running totals and list plays chronologically
SELECT
  period,
  game_clock,
  SUM(CASE WHEN team_market = wildcats_school THEN pts ELSE 0 END)
      OVER (ORDER BY elapsed_time_sec) AS wildcats_score,
  SUM(CASE WHEN team_market = irish_school   THEN pts ELSE 0 END)
      OVER (ORDER BY elapsed_time_sec) AS fighting_irish_score,
  team_market  AS scoring_team,
  event_description
FROM   scoring_events
ORDER BY elapsed_time_sec;