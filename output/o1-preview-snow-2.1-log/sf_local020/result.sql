WITH runs_per_bowler AS (
    SELECT bb."bowler", SUM(COALESCE(bs."runs_scored", 0) + COALESCE(ex."extra_runs", 0)) AS total_runs_conceded
    FROM IPL.IPL."BALL_BY_BALL" bb
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
      ON bb."match_id" = bs."match_id" 
     AND bb."over_id" = bs."over_id"
     AND bb."ball_id" = bs."ball_id"
     AND bb."innings_no" = bs."innings_no"
    LEFT JOIN (
      SELECT er."match_id", er."over_id", er."ball_id", er."innings_no", er."extra_runs"
      FROM IPL.IPL."EXTRA_RUNS" er
      WHERE er."extra_type" IN ('wides', 'noballs')
    ) ex
      ON bb."match_id" = ex."match_id"
     AND bb."over_id" = ex."over_id"
     AND bb."ball_id" = ex."ball_id"
     AND bb."innings_no" = ex."innings_no"
    GROUP BY bb."bowler"
),
wickets_per_bowler AS (
    SELECT bb."bowler", COUNT(*) AS wickets_taken
    FROM IPL.IPL."WICKET_TAKEN" wt
    JOIN IPL.IPL."BALL_BY_BALL" bb
      ON wt."match_id" = bb."match_id"
     AND wt."over_id" = bb."over_id"
     AND wt."ball_id" = bb."ball_id"
     AND wt."innings_no" = bb."innings_no"
    GROUP BY bb."bowler"
    HAVING COUNT(*) >= 10
)
SELECT p."player_name" AS "Bowler_Name", ROUND(rpb.total_runs_conceded / wpb.wickets_taken, 4) AS "Bowling_Average"
FROM runs_per_bowler rpb
JOIN wickets_per_bowler wpb ON rpb."bowler" = wpb."bowler"
JOIN IPL.IPL."PLAYER" p ON rpb."bowler" = p."player_id"
ORDER BY "Bowling_Average" ASC NULLS LAST
LIMIT 1;