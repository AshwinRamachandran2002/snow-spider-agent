SELECT DISTINCT p."player_name"
FROM "ball_by_ball" AS bb
JOIN "batsman_scored" AS bs
  ON bb."match_id" = bs."match_id"
  AND bb."over_id" = bs."over_id"
  AND bb."ball_id" = bs."ball_id"
  AND bb."innings_no" = bs."innings_no"
JOIN "player" AS p
  ON bb."striker" = p."player_id"
JOIN "player_match" AS pm
  ON bb."match_id" = pm."match_id"
  AND bb."striker" = pm."player_id"
JOIN "match" AS m
  ON bb."match_id" = m."match_id"
GROUP BY bb."match_id", bb."striker", pm."team_id"
HAVING SUM(bs."runs_scored") >= 100 AND pm."team_id" <> m."match_winner";