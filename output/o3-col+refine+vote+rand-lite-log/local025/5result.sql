WITH
-- 1. Runs made off the bat by over
bat AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("runs_scored") AS runs
    FROM   "batsman_scored"
    GROUP  BY "match_id","innings_no","over_id"
),
-- 2. Extra runs by over
ext AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("extra_runs") AS runs
    FROM   "extra_runs"
    GROUP  BY "match_id","innings_no","over_id"
),
-- 3. Total runs in every over (bat + extras)
over_totals AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM(runs) AS total_runs
    FROM  (SELECT * FROM bat
           UNION ALL
           SELECT * FROM ext)
    GROUP BY "match_id","innings_no","over_id"
),
-- 4. One bowler per over (any consistent choice; MIN used)
bowler_over AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           MIN("bowler") AS bowler
    FROM   "ball_by_ball"
    GROUP  BY "match_id","innings_no","over_id"
),
-- 5. Attach bowler to each over-total row
over_details AS (
    SELECT ot."match_id",
           ot."innings_no",
           ot."over_id",
           ot."total_runs",
           bo."bowler"
    FROM   over_totals ot
    JOIN   bowler_over bo
      ON   bo."match_id"   = ot."match_id"
     AND   bo."innings_no" = ot."innings_no"
     AND   bo."over_id"    = ot."over_id"
),
-- 6. Pick the single highest-scoring over for every match
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY "match_id"
               ORDER BY "total_runs" DESC,
                        "innings_no",
                        "over_id"
           ) AS rnk
    FROM   over_details
)
-- 7. Compute the average of those highest-scoring overs
SELECT AVG("total_runs") AS avg_highest_over_runs
FROM   ranked
WHERE  rnk = 1;