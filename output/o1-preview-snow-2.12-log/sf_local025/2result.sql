WITH over_totals AS (
  SELECT bs."match_id", bs."innings_no", bs."over_id",
         SUM(bs."runs_scored") + COALESCE(SUM(er."extra_runs"), 0) AS "total_runs"
  FROM IPL.IPL.BATSMAN_SCORED bs
  LEFT JOIN IPL.IPL.EXTRA_RUNS er
    ON bs."match_id" = er."match_id"
    AND bs."innings_no" = er."innings_no"
    AND bs."over_id" = er."over_id"
    AND bs."ball_id" = er."ball_id"
  GROUP BY bs."match_id", bs."innings_no", bs."over_id"
),
bowler_per_over AS (
  SELECT
    bb."match_id",
    bb."innings_no",
    bb."over_id",
    bb."bowler",
    ROW_NUMBER() OVER (
      PARTITION BY bb."match_id", bb."innings_no", bb."over_id"
      ORDER BY bb."ball_id"
    ) AS rn_bowler
  FROM IPL.IPL.BALL_BY_BALL bb
),
highest_over AS (
  SELECT
    ot."match_id",
    ot."innings_no",
    ot."over_id",
    ot."total_runs",
    bpo."bowler",
    ROW_NUMBER() OVER (
      PARTITION BY ot."match_id"
      ORDER BY ot."total_runs" DESC NULLS LAST
    ) AS rn
  FROM over_totals ot
  JOIN bowler_per_over bpo
    ON ot."match_id" = bpo."match_id"
    AND ot."innings_no" = bpo."innings_no"
    AND ot."over_id" = bpo."over_id"
    AND bpo.rn_bowler = 1
)
SELECT ROUND(AVG(h."total_runs"), 4) AS "Average_Highest_Over_Total"
FROM highest_over h
WHERE h.rn = 1;