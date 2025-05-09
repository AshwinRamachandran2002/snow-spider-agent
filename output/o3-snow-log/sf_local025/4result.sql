WITH
-- 1.  Runs off the bat per match / innings / over
bat AS (
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        SUM("runs_scored")        AS "bat_runs"
    FROM IPL.IPL."BATSMAN_SCORED"
    GROUP BY "match_id","innings_no","over_id"
),

-- 2.  Extra runs per match / innings / over
ext AS (
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        SUM("extra_runs")         AS "extra_runs"
    FROM IPL.IPL."EXTRA_RUNS"
    GROUP BY "match_id","innings_no","over_id"
),

-- 3.  Total runs in every over (bat-runs + extras)
tot AS (
    SELECT
        COALESCE(b."match_id",e."match_id")     AS "match_id",
        COALESCE(b."innings_no",e."innings_no") AS "innings_no",
        COALESCE(b."over_id",e."over_id")       AS "over_id",
        COALESCE(b."bat_runs",0)
      + COALESCE(e."extra_runs",0)              AS "total_runs"
    FROM bat b
    FULL JOIN ext e
           ON  b."match_id"   = e."match_id"
           AND b."innings_no" = e."innings_no"
           AND b."over_id"    = e."over_id"
),

-- 4.  For every match keep the single over with the highest total runs
max_over AS (
    SELECT *
    FROM (
        SELECT
            t.*,
            ROW_NUMBER() OVER (PARTITION BY t."match_id"
                               ORDER BY t."total_runs" DESC,
                                        t."innings_no",
                                        t."over_id") AS rn
        FROM tot t
    )
    WHERE rn = 1
),

-- 5.  Identify the bowler who delivered that over
bowler_over AS (
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        MIN("bowler") AS "bowler"     -- one bowler per over; MIN() selects him
    FROM IPL.IPL."BALL_BY_BALL"
    GROUP BY "match_id","innings_no","over_id"
)

-- 6.  Final output:  highest-scoring over per match, its bowler, and overall average
SELECT
    m."match_id",
    m."innings_no",
    m."over_id",
    m."total_runs"                                      AS "highest_over_runs",
    b."bowler",
    AVG(m."total_runs") OVER ()                         AS "avg_highest_over_runs_across_matches"
FROM        max_over      m
INNER JOIN  bowler_over   b
       ON   m."match_id"   = b."match_id"
      AND   m."innings_no" = b."innings_no"
      AND   m."over_id"    = b."over_id"
ORDER BY m."match_id";