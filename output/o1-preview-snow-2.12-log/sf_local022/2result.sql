SELECT p."player_name" AS "striker_name"
FROM IPL.IPL.BATSMAN_SCORED bs
JOIN IPL.IPL.BALL_BY_BALL bb
  ON bs."match_id" = bb."match_id" AND bs."over_id" = bb."over_id" AND bs."ball_id" = bb."ball_id"
JOIN IPL.IPL.MATCH m
  ON bs."match_id" = m."match_id"
JOIN IPL.IPL.PLAYER p
  ON bb."striker" = p."player_id"
WHERE bb."team_batting" != m."match_winner"
GROUP BY p."player_name", bs."match_id"
HAVING SUM(bs."runs_scored") >= 100;