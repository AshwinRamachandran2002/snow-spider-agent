WITH combined AS (
    /* merge batsman and extra runs per over */
    SELECT "match_id", "innings_no", "over_id",
           SUM("runs_scored") AS "runs"
    FROM   "batsman_scored"
    GROUP  BY "match_id", "innings_no", "over_id"
    UNION ALL
    SELECT "match_id", "innings_no", "over_id",
           SUM("extra_runs") AS "runs"
    FROM   "extra_runs"
    GROUP  BY "match_id", "innings_no", "over_id"
),
over_tot AS (
    /* total runs in every over (batsman + extras) */
    SELECT "match_id", "innings_no", "over_id",
           SUM("runs") AS "total_runs"
    FROM   combined
    GROUP  BY "match_id", "innings_no", "over_id"
),
max_run AS (
    /* highest-scoring over total for each match */
    SELECT "match_id",
           MAX("total_runs") AS "max_runs"
    FROM   over_tot
    GROUP  BY "match_id"
),
top_over AS (
    /* the over(s) that reached that maximum (ties kept) */
    SELECT o."match_id", o."innings_no", o."over_id", o."total_runs"
    FROM   over_tot o
    JOIN   max_run  m
           ON  o."match_id"   = m."match_id"
           AND o."total_runs" = m."max_runs"
),
bowled AS (
    /* attach bowler; use MIN to collapse to one row if multiple entries */
    SELECT  t."match_id",
            t."innings_no",
            t."over_id",
            t."total_runs",
            MIN(b."bowler") AS "bowler"
    FROM    top_over      t
    JOIN    "ball_by_ball" b
            ON  b."match_id"   = t."match_id"
            AND b."innings_no" = t."innings_no"
            AND b."over_id"    = t."over_id"
    GROUP BY t."match_id", t."innings_no", t."over_id", t."total_runs"
)
SELECT  b."match_id",
        b."innings_no",
        b."over_id",
        b."total_runs",
        b."bowler",
        /* same average value repeated on every row for convenience */
        (SELECT AVG("max_runs") FROM max_run) AS "average_highest_over_runs"
FROM    bowled b
ORDER BY b."match_id";