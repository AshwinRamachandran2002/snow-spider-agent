-- Task: For each match, identify the maximum runs conceded in a single over.
WITH COMBINED_RUNS AS (
    SELECT "match_id", "over_id", "ball_id", "innings_no", CAST("runs_scored" AS DOUBLE) AS "runs"
    FROM IPL.IPL.BATSMAN_SCORED
    UNION ALL
    SELECT "match_id", "over_id", "ball_id", "innings_no", CAST("extra_runs" AS DOUBLE) AS "runs"
    FROM IPL.IPL.EXTRA_RUNS
),
OVER_RUNS AS (
    SELECT "match_id", "innings_no", "over_id", SUM("runs") AS "runs_scored"
    FROM COMBINED_RUNS
    GROUP BY "match_id", "innings_no", "over_id"
),
MAX_OVER_RUNS AS (
    SELECT "match_id", MAX("runs_scored") AS "max_runs"
    FROM OVER_RUNS
    GROUP BY "match_id"
)
SELECT "match_id", "max_runs"
FROM MAX_OVER_RUNS
ORDER BY "match_id";