SELECT AVG("total_runs") AS "Average_total_score"
FROM (
  SELECT bb."striker", SUM(bs."runs_scored") AS "total_runs"
  FROM IPL.IPL.BALL_BY_BALL bb
  JOIN IPL.IPL.BATSMAN_SCORED bs
    ON bb."match_id" = bs."match_id"
   AND bb."over_id" = bs."over_id"
   AND bb."ball_id" = bs."ball_id"
   AND bb."innings_no" = bs."innings_no"
  WHERE bb."striker" IN (
    SELECT bb2."striker"
    FROM IPL.IPL.BALL_BY_BALL bb2
    JOIN IPL.IPL.BATSMAN_SCORED bs2
      ON bb2."match_id" = bs2."match_id"
     AND bb2."over_id" = bs2."over_id"
     AND bb2."ball_id" = bs2."ball_id"
     AND bb2."innings_no" = bs2."innings_no"
    GROUP BY bb2."striker", bb2."match_id"
    HAVING SUM(bs2."runs_scored") > 50
  )
  GROUP BY bb."striker"
)