WITH "over_runs" AS (
    /* 1.  Total runs in every over (bat + extras)                      */
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        SUM( COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0) ) AS "runs_in_over"
    FROM   "ball_by_ball" AS bb
    LEFT JOIN "batsman_scored" AS bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."innings_no" = bs."innings_no"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
    LEFT JOIN "extra_runs"    AS er
           ON  bb."match_id"   = er."match_id"
           AND bb."innings_no" = er."innings_no"
           AND bb."over_id"    = er."over_id"
           AND bb."ball_id"    = er."ball_id"
    GROUP BY bb."match_id", bb."innings_no", bb."over_id"
),
"highest_over" AS (
    /* 2. Pick the single highest-scoring over for every match & innings */
    SELECT
        o.*,
        RANK() OVER (PARTITION BY o."match_id", o."innings_no"
                     ORDER BY o."runs_in_over" DESC) AS "rnk"
    FROM "over_runs" AS o
),
"highest_over_with_bowler" AS (
    /* 3. Attach the bowler (any ball of that over – use MIN for uniqueness) */
    SELECT
        h."match_id",
        h."innings_no",
        h."over_id",
        h."runs_in_over",
        MIN(bb."bowler") AS "bowler_id"
    FROM "highest_over" AS h
    JOIN "ball_by_ball" AS bb
         ON  h."match_id"   = bb."match_id"
         AND h."innings_no" = bb."innings_no"
         AND h."over_id"    = bb."over_id"
    WHERE h."rnk" = 1
    GROUP BY h."match_id", h."innings_no", h."over_id", h."runs_in_over"
)
 /* 4. Average of those highest-over totals across all matches         */
SELECT ROUND(AVG("runs_in_over"), 4) AS "avg_highest_over_runs"
FROM   "highest_over_with_bowler";