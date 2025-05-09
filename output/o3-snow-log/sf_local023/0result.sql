WITH "season5_matches" AS (
    SELECT "match_id"
    FROM IPL.IPL."MATCH"
    WHERE "season_id" = 5
), 
"player_runs" AS (
    SELECT 
        b."striker"            AS "player_id",
        SUM(s."runs_scored")   AS "total_runs"
    FROM IPL.IPL."BALL_BY_BALL" b
    JOIN IPL.IPL."BATSMAN_SCORED" s
      ON  b."match_id"  = s."match_id"
      AND b."over_id"   = s."over_id"
      AND b."ball_id"   = s."ball_id"
      AND b."innings_no"= s."innings_no"
    WHERE b."match_id" IN (SELECT "match_id" FROM "season5_matches")
    GROUP BY b."striker"
), 
"player_matches" AS (
    SELECT 
        pm."player_id",
        COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM IPL.IPL."PLAYER_MATCH" pm
    JOIN "season5_matches" sm
      ON pm."match_id" = sm."match_id"
    GROUP BY pm."player_id"
), 
"player_average" AS (
    SELECT
        p."player_name",
        ROUND(pr."total_runs" / pm."matches_played", 4) AS "avg_runs_per_match"
    FROM "player_matches" pm
    JOIN "player_runs"  pr ON pm."player_id" = pr."player_id"
    JOIN IPL.IPL."PLAYER" p ON p."player_id" = pm."player_id"
)
SELECT 
    "player_name",
    "avg_runs_per_match"
FROM "player_average"
ORDER BY "avg_runs_per_match" DESC NULLS LAST
LIMIT 5;