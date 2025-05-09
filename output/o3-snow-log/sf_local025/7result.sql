/* Step-1 :  Add batsman runs and extra runs to get total runs per over         */
/* Step-2 :  Pick the single most expensive over for every match & innings     */
/* Step-3 :  Attach the bowler who delivered that over                         */
/* Step-4 :  Take the average of these highest-over totals across all matches  */

WITH over_totals AS (          -- total (bat + extras) runs in every over
    SELECT
        b."match_id",
        b."innings_no",
        b."over_id",
        SUM( b."runs_scored"
            + COALESCE(e."extra_runs",0) )             AS "runs_in_over"
    FROM   IPL.IPL.BATSMAN_SCORED  b
    LEFT JOIN IPL.IPL.EXTRA_RUNS   e
           ON  b."match_id"   = e."match_id"
           AND b."innings_no" = e."innings_no"
           AND b."over_id"    = e."over_id"
           AND b."ball_id"    = e."ball_id"
    GROUP BY
        b."match_id", b."innings_no", b."over_id"
),

best_over_per_innings AS (     -- highest-scoring over per match & innings
    SELECT *
    FROM (
        SELECT
            o.*,
            ROW_NUMBER() OVER (
                PARTITION BY o."match_id", o."innings_no"
                ORDER BY     o."runs_in_over" DESC
            ) AS rn
        FROM over_totals o
    )
    WHERE rn = 1
),

best_over_with_bowler AS (     -- add bowler for that over
    SELECT
        bo."match_id",
        bo."innings_no",
        bo."over_id",
        bo."runs_in_over",
        MIN(bb."bowler") AS "bowler_id"        -- representative bowler
    FROM best_over_per_innings bo
    JOIN IPL.IPL.BALL_BY_BALL bb
      ON bb."match_id"   = bo."match_id"
     AND bb."innings_no" = bo."innings_no"
     AND bb."over_id"    = bo."over_id"
    GROUP BY
        bo."match_id", bo."innings_no", bo."over_id", bo."runs_in_over"
)

SELECT
    AVG("runs_in_over") AS "avg_highest_over_runs"
FROM best_over_with_bowler;