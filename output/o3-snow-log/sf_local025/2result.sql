/* STEP-1 :  Runs scored in every over (batsman runs + all extras)            */
WITH over_runs AS (
    SELECT
        bs."match_id",
        bs."innings_no",
        bs."over_id",
        /* total runs in the over = batsman runs + extras on the same balls   */
        SUM(bs."runs_scored") + COALESCE(SUM(er."extra_runs"),0) AS "total_runs"
    FROM IPL.IPL.BATSMAN_SCORED bs
    LEFT JOIN IPL.IPL.EXTRA_RUNS er
           ON er."match_id"   = bs."match_id"
          AND er."innings_no" = bs."innings_no"
          AND er."over_id"    = bs."over_id"
          AND er."ball_id"    = bs."ball_id"
    GROUP BY
        bs."match_id",
        bs."innings_no",
        bs."over_id"
),

/* STEP-2 :  Identify the bowler who delivered each over                      */
/*          (all six balls of an over are bowled by the same bowler)          */
over_bowler AS (
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        MIN(bb."bowler") AS "bowler"          -- unique bowler per over
    FROM IPL.IPL.BALL_BY_BALL bb
    GROUP BY
        bb."match_id",
        bb."innings_no",
        bb."over_id"
),

/* STEP-3 :  For every match, pick the single highest-scoring over            */
highest_over_per_match AS (
    SELECT
        o."match_id",
        o."innings_no",
        o."over_id",
        o."total_runs"                       AS "highest_over_runs",
        ob."bowler",
        ROW_NUMBER() OVER (PARTITION BY o."match_id"
                           ORDER BY o."total_runs" DESC NULLS LAST) AS rn
    FROM over_runs o
    LEFT JOIN over_bowler ob
           ON  ob."match_id"   = o."match_id"
           AND ob."innings_no" = o."innings_no"
           AND ob."over_id"    = o."over_id"
)

/* STEP-4 :  Compute the average of these peak-over totals across matches     */
SELECT
    AVG("highest_over_runs") AS "avg_highest_over_runs_across_matches"
FROM highest_over_per_match
WHERE rn = 1;