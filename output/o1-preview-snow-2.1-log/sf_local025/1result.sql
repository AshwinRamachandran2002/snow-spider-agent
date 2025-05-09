WITH RunsPerBall AS (
  SELECT bs."match_id", bs."over_id", bs."innings_no",
         bs."runs_scored" + COALESCE(er."extra_runs", 0) AS "runs_per_ball"
  FROM "IPL"."IPL"."BATSMAN_SCORED" bs
  LEFT JOIN "IPL"."IPL"."EXTRA_RUNS" er
    ON bs."match_id" = er."match_id"
    AND bs."over_id" = er."over_id"
    AND bs."ball_id" = er."ball_id"
    AND bs."innings_no" = er."innings_no"
),
RunsPerOver AS (
  SELECT "match_id", "over_id", SUM("runs_per_ball") AS "runs_in_over"
  FROM RunsPerBall
  GROUP BY "match_id", "over_id"
),
MaxRunsPerMatch AS (
  SELECT "match_id", MAX("runs_in_over") AS "max_runs_in_over"
  FROM RunsPerOver
  GROUP BY "match_id"
)
SELECT ROUND(AVG("max_runs_in_over"), 4) AS "average_runs_conceded_per_over"
FROM MaxRunsPerMatch;