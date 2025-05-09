WITH PLAYER_MATCH_RUNS AS (
    SELECT
        bbb."match_id",
        bbb."striker"                   AS "player_id",
        SUM(bsc."runs_scored")          AS "total_runs"
    FROM "IPL"."IPL"."BALL_BY_BALL"    bbb
    JOIN "IPL"."IPL"."BATSMAN_SCORED"  bsc
      ON bbb."match_id"   = bsc."match_id"
     AND bbb."over_id"    = bsc."over_id"
     AND bbb."ball_id"    = bsc."ball_id"
     AND bbb."innings_no" = bsc."innings_no"
    GROUP BY
        bbb."match_id",
        bbb."striker"
)
SELECT
    ROUND(AVG("total_runs"), 4) AS "average_total_runs"
FROM PLAYER_MATCH_RUNS
WHERE "total_runs" > 50;