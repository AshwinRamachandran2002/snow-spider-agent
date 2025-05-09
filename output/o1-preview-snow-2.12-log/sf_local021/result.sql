WITH runs_per_match AS (
  SELECT bbb."striker", bbb."match_id", SUM(bs."runs_scored") AS "total_runs_per_match"
  FROM IPL.IPL."BALL_BY_BALL" AS bbb
  JOIN IPL.IPL."BATSMAN_SCORED" AS bs
    ON bbb."match_id" = bs."match_id"
   AND bbb."over_id" = bs."over_id"
   AND bbb."ball_id" = bs."ball_id"
   AND bbb."innings_no" = bs."innings_no"
  GROUP BY bbb."striker", bbb."match_id"
),
strikers_over_50 AS (
  SELECT DISTINCT "striker"
  FROM runs_per_match
  WHERE "total_runs_per_match" > 50
),
total_runs_per_striker AS (
  SELECT bbb."striker", SUM(bs."runs_scored") AS "total_runs"
  FROM IPL.IPL."BALL_BY_BALL" AS bbb
  JOIN IPL.IPL."BATSMAN_SCORED" AS bs
    ON bbb."match_id" = bs."match_id"
   AND bbb."over_id" = bs."over_id"
   AND bbb."ball_id" = bs."ball_id"
   AND bbb."innings_no" = bs."innings_no"
  WHERE bbb."striker" IN (SELECT "striker" FROM strikers_over_50)
  GROUP BY bbb."striker"
)
SELECT ROUND(AVG("total_runs"), 4) AS "Average_total_score"
FROM total_runs_per_striker;