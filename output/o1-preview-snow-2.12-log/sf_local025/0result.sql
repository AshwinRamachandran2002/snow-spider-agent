SELECT AVG("total_runs_in_over") AS "Average_Highest_Over_Total"
FROM (
  WITH delivery_runs AS (
    SELECT bbb."match_id", bbb."innings_no", bbb."over_id", bbb."ball_id", bbb."bowler",
           COALESCE(bs."runs_scored", 0) AS "runs_scored",
           COALESCE(er."extra_runs", 0) AS "extra_runs",
           COALESCE(bs."runs_scored", 0) + COALESCE(er."extra_runs", 0) AS "total_runs"
    FROM IPL.IPL.BALL_BY_BALL bbb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
      ON bbb."match_id" = bs."match_id"
     AND bbb."innings_no" = bs."innings_no"
     AND bbb."over_id" = bs."over_id"
     AND bbb."ball_id" = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS er
      ON bbb."match_id" = er."match_id"
     AND bbb."innings_no" = er."innings_no"
     AND bbb."over_id" = er."over_id"
     AND bbb."ball_id" = er."ball_id"
  ),
  over_runs AS (
    SELECT dr."match_id", dr."innings_no", dr."over_id",
           MIN_BY(dr."bowler", dr."ball_id") AS "bowler",
           SUM(dr."total_runs") AS "total_runs_in_over"
    FROM delivery_runs dr
    GROUP BY dr."match_id", dr."innings_no", dr."over_id"
  ),
  top_overs AS (
    SELECT "match_id", "innings_no", "over_id", "bowler", "total_runs_in_over",
           RANK() OVER (PARTITION BY "match_id", "innings_no"
                        ORDER BY "total_runs_in_over" DESC NULLS LAST) AS "over_rank"
    FROM over_runs
  )
  SELECT "total_runs_in_over"
  FROM top_overs
  WHERE "over_rank" = 1
)
;