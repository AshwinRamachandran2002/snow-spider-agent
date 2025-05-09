WITH "PLAYER_RUNS" AS (
    /* total runs scored by each striker in every match */
    SELECT
        b."match_id",
        bb."striker"            AS "player_id",
        SUM(b."runs_scored")    AS "total_runs"
    FROM IPL.IPL."BATSMAN_SCORED" b
    JOIN IPL.IPL."BALL_BY_BALL"  bb
      ON  b."match_id"    = bb."match_id"
      AND b."innings_no"  = bb."innings_no"
      AND b."over_id"     = bb."over_id"
      AND b."ball_id"     = bb."ball_id"
    GROUP BY
        b."match_id",
        bb."striker"
)

/* average of all individual match-innings where the striker scored > 50 */
SELECT
    ROUND(AVG("total_runs"), 4) AS "average_runs"
FROM "PLAYER_RUNS"
WHERE "total_runs" > 50;