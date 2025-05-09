SELECT DISTINCT p."player_name"
FROM (
  SELECT b."match_id", b."striker", b."innings_no", b."team_batting", SUM(s."runs_scored") AS total_runs
  FROM "ball_by_ball" AS b
  JOIN "batsman_scored" AS s
    ON b."match_id" = s."match_id"
   AND b."over_id" = s."over_id"
   AND b."ball_id" = s."ball_id"
   AND b."innings_no" = s."innings_no"
  GROUP BY b."match_id", b."striker", b."innings_no", b."team_batting"
  HAVING SUM(s."runs_scored") >= 100
) AS t_runs
JOIN "match" AS m
  ON t_runs."match_id" = m."match_id"
JOIN "player" AS p
  ON t_runs."striker" = p."player_id"
WHERE t_runs."team_batting" != m."match_winner"
  AND m."match_winner" IS NOT NULL;