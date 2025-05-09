/*  Chronological list of every 2014-season scoring play
    – Wildcats (home) vs Fighting Irish (away) –
    with running totals for both teams.  */

WITH games AS (    -- identify the one 2014 game that matches
    SELECT DISTINCT "game_id"
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE  "season" = 2014
      AND  ( "home_market" ILIKE '%Wildcats%'  OR "home_name" ILIKE '%Wildcats%' )
      AND  ( "away_market" ILIKE '%Fighting%Irish%'  OR "away_name" ILIKE '%Fighting%Irish%' )
),

ids AS (           -- grab the SportRadar team-ids for each side
    SELECT DISTINCT
           "game_id",
           "home_id" AS wildcats_id,
           "away_id" AS irish_id
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE  "game_id" IN (SELECT "game_id" FROM games)
),

scoring_events AS (   -- all plays that scored points (> 0)
    SELECT
           m."game_id",
           m."period",
           m."game_clock",
           m."elapsed_time_sec",
           m."team_id",
           m."points_scored",
           m."event_description",
           i.wildcats_id,
           i.irish_id
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR m
    JOIN   ids i
           ON  m."game_id" = i."game_id"
    WHERE  m."points_scored" IS NOT NULL
      AND  m."points_scored" > 0
)

SELECT
       s."period",
       s."game_clock",
       /* running total for each team, ordered by actual game time */
       SUM( CASE WHEN s."team_id" = s.wildcats_id THEN s."points_scored" ELSE 0 END )
           OVER (ORDER BY s."elapsed_time_sec")          AS "wildcats_pts",
       SUM( CASE WHEN s."team_id" = s.irish_id    THEN s."points_scored" ELSE 0 END )
           OVER (ORDER BY s."elapsed_time_sec")          AS "fighting_irish_pts",
       CASE WHEN s."team_id" = s.wildcats_id
            THEN 'Wildcats' ELSE 'Fighting Irish' END    AS "scoring_team",
       s."event_description"
FROM   scoring_events s
ORDER  BY s."elapsed_time_sec";