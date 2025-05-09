WITH wildcats_vs_irish AS (
    /* Identify the 2014-season game where the Wildcats were home
       and the Fighting Irish were away.  */
    SELECT "game_id"
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_GAMES_SR"
    WHERE  "season" = 2014
      AND  "h_name" ILIKE '%Wildcats%'
      AND  "a_name" ILIKE '%Fighting%Irish%'
    LIMIT 1
)

SELECT
    pbp."period",
    pbp."game_clock",
    pbp."elapsed_time_sec",
    /* Team that scored on this play */
    COALESCE(pbp."team_market", pbp."team_name")                         AS "scoring_team",
    pbp."points_scored",
    /* Running total for the home Wildcats */
    SUM(
        CASE 
            WHEN COALESCE(pbp."team_market", pbp."team_name") ILIKE '%Wildcats%'
            THEN pbp."points_scored" 
            ELSE 0 
        END
    ) OVER (ORDER BY pbp."elapsed_time_sec")                             AS "wildcats_cumulative",
    /* Running total for the visiting Fighting Irish */
    SUM(
        CASE 
            WHEN COALESCE(pbp."team_market", pbp."team_name") ILIKE '%Fighting%Irish%'
            THEN pbp."points_scored" 
            ELSE 0 
        END
    ) OVER (ORDER BY pbp."elapsed_time_sec")                             AS "irish_cumulative",
    pbp."event_description"
FROM   NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR" pbp
JOIN   wildcats_vs_irish g
       ON pbp."game_id" = g."game_id"
WHERE  pbp."points_scored" > 0
ORDER BY pbp."elapsed_time_sec";