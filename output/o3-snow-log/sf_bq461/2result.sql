-- chronological scoring summary for the 2014 season game
-- where the home team is the Wildcats and the away team is the Fighting Irish
WITH target_game AS (
    /* identify the unique game_id that matches the criteria */
    SELECT DISTINCT "game_id"
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR"
    WHERE  "season"      = 2014
      AND  "home_name"  ILIKE '%Wildcats%'
      AND  "away_name"  ILIKE '%Irish%'      -- Fighting Irish
)
SELECT
    p."period",                       -- half / OT indicator
    p."game_clock",                   -- time remaining in the period
    /* team that scored on this play */
    CASE
        WHEN p."team_name" ILIKE '%Wildcats%' THEN 'Wildcats'
        WHEN p."team_name" ILIKE '%Irish%'    THEN 'Fighting Irish'
        ELSE p."team_name"
    END AS "scoring_team",
    /* running totals after this basket/free-throw */
    SUM(CASE WHEN p."team_name" ILIKE '%Wildcats%' THEN COALESCE(p."points_scored",0) ELSE 0 END)
        OVER (ORDER BY p."period", p."elapsed_time_sec", p."event_id")  AS "wildcats_total",
    SUM(CASE WHEN p."team_name" ILIKE '%Irish%' THEN COALESCE(p."points_scored",0) ELSE 0 END)
        OVER (ORDER BY p."period", p."elapsed_time_sec", p."event_id")  AS "fighting_irish_total",
    p."event_description"             -- description of the scoring play
FROM   NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR"  p
JOIN   target_game g
       ON p."game_id" = g."game_id"
WHERE  p."points_scored" IS NOT NULL           -- keep only scoring events
ORDER  BY p."period", p."elapsed_time_sec", p."event_id";