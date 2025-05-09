WITH total_runs_per_over AS (
    SELECT 
        b."match_id",
        b."over_id",
        b."innings_no",
        SUM(b."runs_scored" + COALESCE(e."extra_runs", 0)) AS "total_runs"
    FROM IPL.IPL."BATSMAN_SCORED" b
    LEFT JOIN IPL.IPL."EXTRA_RUNS" e
        ON b."match_id" = e."match_id"
        AND b."over_id" = e."over_id"
        AND b."ball_id" = e."ball_id"
        AND b."innings_no" = e."innings_no"
    GROUP BY b."match_id", b."over_id", b."innings_no"
),
max_runs_per_match AS (
    SELECT 
        "match_id", 
        MAX("total_runs") AS "max_runs_in_over"
    FROM total_runs_per_over
    GROUP BY "match_id"
)
SELECT 
    CAST(AVG("max_runs_in_over") AS DECIMAL(10,4)) AS "average_runs_conceded_per_over"
FROM max_runs_per_match;