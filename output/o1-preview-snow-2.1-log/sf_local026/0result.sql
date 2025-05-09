SELECT p."player_name" AS "bowler_name", b."match_id",
  SUM(bs."runs_scored" + COALESCE(er."extra_runs", 0)) AS "runs_conceded_in_one_over"
FROM IPL.IPL.BALL_BY_BALL b
JOIN IPL.IPL.PLAYER p ON b."bowler" = p."player_id"
LEFT JOIN IPL.IPL.BATSMAN_SCORED bs ON b."match_id" = bs."match_id"
  AND b."over_id" = bs."over_id"
  AND b."ball_id" = bs."ball_id"
LEFT JOIN IPL.IPL.EXTRA_RUNS er ON b."match_id" = er."match_id"
  AND b."over_id" = er."over_id"
  AND b."ball_id" = er."ball_id"
GROUP BY p."player_name", b."match_id", b."over_id"
ORDER BY "runs_conceded_in_one_over" DESC NULLS LAST
LIMIT 3;