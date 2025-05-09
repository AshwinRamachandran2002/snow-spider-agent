SELECT DISTINCT p."player_name"
FROM (
        SELECT   bb."striker"      AS "player_id",
                 bb."match_id",
                 bb."team_batting" AS "player_team",
                 SUM(bs."runs_scored") AS "total_runs"
        FROM     "ball_by_ball"  AS bb
        JOIN     "batsman_scored" AS bs
               ON  bb."match_id"   = bs."match_id"
               AND bb."over_id"    = bs."over_id"
               AND bb."ball_id"    = bs."ball_id"
               AND bb."innings_no" = bs."innings_no"
        GROUP BY bb."match_id", bb."striker"
        HAVING   SUM(bs."runs_scored") >= 100
     ) AS t
JOIN "match"  AS m  ON m."match_id" = t."match_id"
JOIN "player" AS p  ON p."player_id" = t."player_id"
WHERE m."match_winner" IS NOT NULL      -- match had a winner
  AND t."player_team" <> m."match_winner"  -- player's team lost
ORDER BY p."player_name";