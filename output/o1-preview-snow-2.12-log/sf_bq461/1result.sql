WITH scoring_events AS (
    SELECT
        "period",
        "game_clock",
        "elapsed_time_sec",
        "team_name",
        "points_scored",
        "event_description"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE
        "game_id" = '95cda731-b593-42cd-8573-621a3d1369dc'
        AND "points_scored" IS NOT NULL
),
team_scores AS (
    SELECT
        se.*,
        SUM(CASE WHEN se."team_name" = 'Wildcats' THEN se."points_scored" ELSE 0 END) OVER (ORDER BY se."period", se."elapsed_time_sec") AS "wildcats_score",
        SUM(CASE WHEN se."team_name" = 'Fighting Irish' THEN se."points_scored" ELSE 0 END) OVER (ORDER BY se."period", se."elapsed_time_sec") AS "fighting_irish_score"
    FROM scoring_events se
)
SELECT
    "period" AS "Period",
    "game_clock" AS "Game Clock",
    CONCAT(TO_CHAR(ROUND("wildcats_score", 4)), '-', TO_CHAR(ROUND("fighting_irish_score", 4))) AS "Team Scores",
    "team_name" AS "Scoring Team",
    "event_description" AS "Event Description"
FROM team_scores
ORDER BY "period", "elapsed_time_sec";