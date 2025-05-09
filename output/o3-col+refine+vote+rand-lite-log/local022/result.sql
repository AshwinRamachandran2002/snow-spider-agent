SELECT DISTINCT p."player_name"
FROM "player" AS p
JOIN (
    SELECT 
        bb."striker"      AS player_id,
        bs."match_id",
        bb."team_batting" AS team_id
    FROM "batsman_scored" AS bs
    JOIN "ball_by_ball" AS bb
      ON bs."match_id"   = bb."match_id"
     AND bs."over_id"    = bb."over_id"
     AND bs."ball_id"    = bb."ball_id"
     AND bs."innings_no" = bb."innings_no"
    GROUP BY bs."match_id", bb."striker", bb."team_batting"
    HAVING SUM(bs."runs_scored") >= 100
) AS c
JOIN "match" AS m
  ON c."match_id" = m."match_id"
WHERE c."team_id" <> m."match_winner"
  AND p."player_id" = c."player_id"
ORDER BY p."player_name";