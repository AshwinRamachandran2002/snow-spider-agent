SELECT
  p."player_name" AS bowler_name,
  bb."match_id",
  SUM(COALESCE(bs."runs_scored", 0) + COALESCE(er."extra_runs", 0)) AS runs_conceded_in_one_over
FROM "IPL"."IPL"."BALL_BY_BALL" bb
LEFT JOIN "IPL"."IPL"."BATSMAN_SCORED" bs
  ON bb."match_id" = bs."match_id" 
  AND bb."over_id" = bs."over_id" 
  AND bb."ball_id" = bs."ball_id"
LEFT JOIN "IPL"."IPL"."EXTRA_RUNS" er
  ON bb."match_id" = er."match_id" 
  AND bb."over_id" = er."over_id" 
  AND bb."ball_id" = er."ball_id"
JOIN "IPL"."IPL"."PLAYER" p
  ON bb."bowler" = p."player_id"
GROUP BY
  p."player_name",
  bb."match_id",
  bb."over_id"
ORDER BY
  runs_conceded_in_one_over DESC NULLS LAST
LIMIT 3;