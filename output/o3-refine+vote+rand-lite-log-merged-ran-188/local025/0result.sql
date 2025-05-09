WITH
-- 1) Runs scored from the bat plus extras, aggregated per over
"br" AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("runs_scored") AS "runs"
    FROM   "batsman_scored"
    GROUP  BY "match_id","innings_no","over_id"
),
"er" AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("extra_runs") AS "runs"
    FROM   "extra_runs"
    GROUP  BY "match_id","innings_no","over_id"
),
"over_totals" AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("runs") AS "total_runs"
    FROM   (SELECT * FROM "br"
            UNION ALL
            SELECT * FROM "er")
    GROUP  BY "match_id","innings_no","over_id"
),

-- 2) Highest-scoring run total for every match
"max_per_match" AS (
    SELECT "match_id",
           MAX("total_runs") AS "max_runs"
    FROM   "over_totals"
    GROUP  BY "match_id"
),

-- 3) All overs that reach that highest total (there may be ties)
"candidates" AS (
    SELECT ot.*
    FROM   "over_totals" ot
    JOIN   "max_per_match" mp
           ON  ot."match_id"   = mp."match_id"
           AND ot."total_runs" = mp."max_runs"
),

-- 4) Pick one single over per match (earliest over in case of ties)
"chosen_over" AS (
    SELECT c.*
    FROM   "candidates" c
    JOIN  (
           SELECT "match_id",
                  MIN("innings_no"*100 + "over_id") AS "min_key"
           FROM   "candidates"
           GROUP  BY "match_id"
          ) k
          ON  c."match_id" = k."match_id"
          AND (c."innings_no"*100 + c."over_id") = k."min_key"
),

-- 5) Attach the bowler for that over
"with_bowler" AS (
    SELECT  co."match_id",
            co."innings_no",
            co."over_id",
            co."total_runs",
            MIN(bb."bowler") AS "bowler"   -- each over has one bowler; MIN() gives that value
    FROM    "chosen_over"   co
    JOIN    "ball_by_ball"  bb
            ON  co."match_id"  = bb."match_id"
            AND co."innings_no"= bb."innings_no"
            AND co."over_id"   = bb."over_id"
    GROUP BY co."match_id",
             co."innings_no",
             co."over_id",
             co."total_runs"
),

-- 6) Average of these highest-over totals across all matches
"avg_high" AS (
    SELECT AVG("total_runs") AS "average_highest_over_runs"
    FROM   "with_bowler"
)

-- 7) Final output: over details for every match    + the overall average
SELECT wb."match_id",
       wb."innings_no",
       wb."over_id",
       wb."total_runs",
       wb."bowler",
       ah."average_highest_over_runs"
FROM   "with_bowler" wb
CROSS  JOIN "avg_high" ah
ORDER  BY wb."match_id";