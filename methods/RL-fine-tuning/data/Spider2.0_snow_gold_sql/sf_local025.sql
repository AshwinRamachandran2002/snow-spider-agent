WITH total_runs_per_over AS (
  SELECT "match_id", "innings_no", "over_id", SUM("runs_scored") AS "runs_scored"
  FROM "IPL"."IPL"."BATSMAN_SCORED"
  GROUP BY "match_id", "innings_no", "over_id"
),
extra_runs_per_over AS (
  SELECT "match_id", "innings_no", "over_id", SUM("extra_runs") AS "extra_runs"
  FROM "IPL"."IPL"."EXTRA_RUNS"
  GROUP BY "match_id", "innings_no", "over_id"
),
over_total_runs AS (
  SELECT 
    COALESCE(tr."match_id", er."match_id") AS "match_id",
    COALESCE(tr."innings_no", er."innings_no") AS "innings_no",
    COALESCE(tr."over_id", er."over_id") AS "over_id",
    COALESCE(tr."runs_scored", 0) + COALESCE(er."extra_runs", 0) AS "over_total_runs"
  FROM total_runs_per_over tr
  FULL OUTER JOIN extra_runs_per_over er
    ON tr."match_id" = er."match_id"
    AND tr."innings_no" = er."innings_no"
    AND tr."over_id" = er."over_id"
),
over_bowlers AS (
  SELECT 
    "match_id", 
    "innings_no", 
    "over_id", 
    "bowler"
  FROM (
    SELECT 
      "match_id", 
      "innings_no", 
      "over_id", 
      "bowler",
      ROW_NUMBER() OVER (PARTITION BY "match_id", "innings_no", "over_id" ORDER BY "ball_id") AS rn
    FROM "IPL"."IPL"."BALL_BY_BALL"
  ) ob
  WHERE rn = 1
),
over_runs_bowlers AS (
  SELECT otr."match_id", otr."innings_no", otr."over_id", otr."over_total_runs", ob."bowler"
  FROM over_total_runs otr
  JOIN over_bowlers ob
    ON otr."match_id" = ob."match_id" AND otr."innings_no" = ob."innings_no" AND otr."over_id" = ob."over_id"
),
highest_over_per_innings AS (
  SELECT "match_id", "innings_no", "over_id", "over_total_runs", "bowler",
         ROW_NUMBER() OVER (
           PARTITION BY "match_id", "innings_no" 
           ORDER BY "over_total_runs" DESC NULLS LAST, "over_id"
         ) AS rn
  FROM over_runs_bowlers
),
final_highest_overs AS (
  SELECT "match_id", "innings_no", "over_id", "over_total_runs", "bowler"
  FROM highest_over_per_innings
  WHERE rn = 1
)
SELECT ROUND(AVG("over_total_runs"), 4) AS "Average_Highest_Over_Total"
FROM final_highest_overs;