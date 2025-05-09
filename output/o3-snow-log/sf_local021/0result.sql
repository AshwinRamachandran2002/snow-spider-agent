WITH "player_runs" AS (
    SELECT
        bb."striker"  AS "player_id",
        bb."match_id" AS "match_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL."BALL_BY_BALL"  bb
    JOIN IPL.IPL."BATSMAN_SCORED" bs
      ON bb."match_id"   = bs."match_id"
     AND bb."innings_no" = bs."innings_no"
     AND bb."over_id"    = bs."over_id"
     AND bb."ball_id"    = bs."ball_id"
    GROUP BY
        bb."striker",
        bb."match_id"
),
"qualified_runs" AS (
    SELECT "total_runs"
    FROM "player_runs"
    WHERE "total_runs" > 50
)
SELECT
    ROUND(AVG("total_runs"), 4) AS "average_runs"
FROM "qualified_runs";