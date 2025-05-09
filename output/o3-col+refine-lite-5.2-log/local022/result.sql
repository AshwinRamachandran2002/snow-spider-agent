SELECT DISTINCT p."player_name"
FROM (
    SELECT 
        b."match_id",
        b."striker"        AS player_id,
        b."team_batting"   AS team_id,
        SUM(s."runs_scored") AS total_runs
    FROM "ball_by_ball"   AS b
    JOIN "batsman_scored" AS s
         ON s."match_id"   = b."match_id"
        AND s."over_id"    = b."over_id"
        AND s."ball_id"    = b."ball_id"
        AND s."innings_no" = b."innings_no"
    GROUP BY b."match_id", b."striker", b."team_batting"
    HAVING SUM(s."runs_scored") >= 100
) AS t
JOIN "match"  AS m ON m."match_id" = t."match_id"
JOIN "player" AS p ON p."player_id" = t."player_id"
WHERE m."match_winner" IS NOT NULL      -- ensure the match had a winner
  AND t."team_id" <> m."match_winner";  -- centurion's team lost