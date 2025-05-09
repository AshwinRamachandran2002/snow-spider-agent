WITH batsman_runs AS (
  SELECT
    "match_id",
    "innings_no",
    "over_id",
    SUM("runs_scored") AS "batsman_runs_in_over"
  FROM IPL.IPL."BATSMAN_SCORED"
  GROUP BY "match_id", "innings_no", "over_id"
),
extra_runs AS (
  SELECT
    "match_id",
    "innings_no",
    "over_id",
    SUM("extra_runs") AS "extra_runs_in_over"
  FROM IPL.IPL."EXTRA_RUNS"
  GROUP BY "match_id", "innings_no", "over_id"
),
total_runs_per_over AS (
  SELECT
    COALESCE(br."match_id", er."match_id") AS "match_id",
    COALESCE(br."innings_no", er."innings_no") AS "innings_no",
    COALESCE(br."over_id", er."over_id") AS "over_id",
    COALESCE(br."batsman_runs_in_over", 0) + COALESCE(er."extra_runs_in_over", 0) AS "total_runs_in_over"
  FROM batsman_runs br
  FULL OUTER JOIN extra_runs er
    ON br."match_id" = er."match_id"
    AND br."innings_no" = er."innings_no"
    AND br."over_id" = er."over_id"
),
max_runs_per_match AS (
  SELECT
    "match_id",
    MAX("total_runs_in_over") AS "max_runs_in_match"
  FROM total_runs_per_over
  GROUP BY "match_id"
)
SELECT
  ROUND(AVG("max_runs_in_match"), 4) AS "average_runs_conceded_per_over"
FROM max_runs_per_match;