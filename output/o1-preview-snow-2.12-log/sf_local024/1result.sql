SELECT
  p."country_name" AS "Country",
  ROUND(SUM(bs."runs_scored") / COUNT(DISTINCT b."match_id"), 4) AS "Average_Runs_per_Match",
  ROUND(SUM(bs."runs_scored") / NULLIF(COUNT(wt."player_out"), 0), 4) AS "Batting_Average"
FROM "IPL"."IPL"."PLAYER" p
JOIN "IPL"."IPL"."BALL_BY_BALL" b
  ON p."player_id" = b."striker"
JOIN "IPL"."IPL"."BATSMAN_SCORED" bs
  ON b."match_id" = bs."match_id"
  AND b."over_id" = bs."over_id"
  AND b."ball_id" = bs."ball_id"
LEFT JOIN "IPL"."IPL"."WICKET_TAKEN" wt
  ON b."match_id" = wt."match_id"
  AND b."over_id" = wt."over_id"
  AND b."ball_id" = wt."ball_id"
  AND b."striker" = wt."player_out"
GROUP BY p."country_name"
ORDER BY "Average_Runs_per_Match" DESC NULLS LAST
LIMIT 5;