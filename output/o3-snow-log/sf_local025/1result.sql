WITH bat AS (   -- runs scored off the bat per (match, innings, over)
    SELECT 
        "match_id",
        "innings_no",
        "over_id",
        SUM("runs_scored") AS "bat_runs"
    FROM IPL.IPL.BATSMAN_SCORED
    GROUP BY "match_id","innings_no","over_id"
),
ext AS (   -- extra runs per (match, innings, over)
    SELECT 
        "match_id",
        "innings_no",
        "over_id",
        SUM("extra_runs") AS "extra_runs"
    FROM IPL.IPL.EXTRA_RUNS
    GROUP BY "match_id","innings_no","over_id"
),
over_totals AS (   -- combine bat + extras to get total runs per over
    SELECT 
        COALESCE(bat."match_id",ext."match_id")     AS "match_id",
        COALESCE(bat."innings_no",ext."innings_no") AS "innings_no",
        COALESCE(bat."over_id",ext."over_id")       AS "over_id",
        NVL(bat."bat_runs",0) + NVL(ext."extra_runs",0) AS "total_runs"
    FROM bat
    FULL OUTER JOIN ext
      ON bat."match_id"   = ext."match_id"
     AND bat."innings_no" = ext."innings_no"
     AND bat."over_id"    = ext."over_id"
),
over_with_bowler AS (  -- attach the bowler who delivered the over
    SELECT
        ot."match_id",
        ot."innings_no",
        ot."over_id",
        ot."total_runs",
        MIN(bbb."bowler") AS "bowler"   -- only one bowler should exist per over
    FROM over_totals ot
    JOIN IPL.IPL.BALL_BY_BALL bbb
      ON ot."match_id"   = bbb."match_id"
     AND ot."innings_no" = bbb."innings_no"
     AND ot."over_id"    = bbb."over_id"
    GROUP BY
        ot."match_id",
        ot."innings_no",
        ot."over_id",
        ot."total_runs"
),
best_over_per_match AS (  -- pick the single highest-scoring over in each match
    SELECT
        owb.*,
        ROW_NUMBER() OVER (PARTITION BY owb."match_id" 
                           ORDER BY owb."total_runs" DESC, owb."innings_no", owb."over_id") AS "rn"
    FROM over_with_bowler owb
)
-- final answer: average of those highest-scoring overs across all matches
SELECT 
    AVG("total_runs") AS "avg_highest_over_runs"
FROM best_over_per_match
WHERE "rn" = 1;