-- Task: Could you list all strikers and matches where the striker scored more than 50 runs?
SELECT bbb."striker", bbb."match_id", SUM(bs."runs_scored") AS "total_runs_per_match"
FROM IPL.IPL."BALL_BY_BALL" AS bbb
JOIN IPL.IPL."BATSMAN_SCORED" AS bs
  ON bbb."match_id" = bs."match_id"
     AND bbb."over_id" = bs."over_id"
     AND bbb."ball_id" = bs."ball_id"
     AND bbb."innings_no" = bs."innings_no"
GROUP BY bbb."striker", bbb."match_id"
HAVING SUM(bs."runs_scored") > 50
LIMIT 100;