WITH "PLAYER_RUNS" AS (
    SELECT
        bbb."match_id",
        bbb."striker"                     AS "player_id",
        SUM(bs."runs_scored")             AS "total_runs"
    FROM "IPL"."IPL"."BATSMAN_SCORED" bs
    JOIN "IPL"."IPL"."BALL_BY_BALL"   bbb
      ON bs."match_id"    = bbb."match_id"
     AND bs."innings_no"  = bbb."innings_no"
     AND bs."over_id"     = bbb."over_id"
     AND bs."ball_id"     = bbb."ball_id"
    GROUP BY
        bbb."match_id",
        bbb."striker"
)
SELECT
    ROUND(AVG("total_runs"), 4) AS "avg_runs_above_50"
FROM "PLAYER_RUNS"
WHERE "total_runs" > 50;