WITH "PLAYER_MATCH_RUNS" AS (
    SELECT
        bb."match_id",
        bb."striker"      AS "player_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM
        IPL.IPL."BATSMAN_SCORED" bs
        JOIN IPL.IPL."BALL_BY_BALL" bb
          ON bs."match_id"   = bb."match_id"
         AND bs."over_id"    = bb."over_id"
         AND bs."ball_id"    = bb."ball_id"
         AND bs."innings_no" = bb."innings_no"
    GROUP BY
        bb."match_id",
        bb."striker"
)
SELECT
    ROUND(AVG("total_runs"), 4) AS "average_runs"
FROM
    "PLAYER_MATCH_RUNS"
WHERE
    "total_runs" > 50;