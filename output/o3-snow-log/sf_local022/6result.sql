WITH "player_runs" AS (
    SELECT
        b."match_id",
        bb."striker"       AS "player_id",
        bb."team_batting"  AS "team_id",
        SUM(b."runs_scored") AS "total_runs"
    FROM IPL.IPL."BATSMAN_SCORED" b
    JOIN IPL.IPL."BALL_BY_BALL"   bb
         ON bb."match_id"   = b."match_id"
        AND bb."over_id"    = b."over_id"
        AND bb."ball_id"    = b."ball_id"
        AND bb."innings_no" = b."innings_no"
    GROUP BY
        b."match_id",
        bb."striker",
        bb."team_batting"
    HAVING SUM(b."runs_scored") >= 100
)

SELECT DISTINCT
       p."player_name"
FROM "player_runs"          pr
JOIN IPL.IPL."MATCH"        m  ON m."match_id"  = pr."match_id"
JOIN IPL.IPL."PLAYER"       p  ON p."player_id" = pr."player_id"
WHERE m."match_winner" IS NOT NULL
  AND pr."team_id" <> m."match_winner"
ORDER BY p."player_name" NULLS LAST;