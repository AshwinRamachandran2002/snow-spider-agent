WITH player_runs AS (      -- runs scored by every batsman in every match
    SELECT 
        bs."match_id",
        bb."striker"                            AS "player_id",
        SUM(bs."runs_scored")                   AS "total_runs"
    FROM "IPL"."IPL"."BATSMAN_SCORED" bs
    JOIN "IPL"."IPL"."BALL_BY_BALL"  bb
         ON  bs."match_id"   = bb."match_id"
         AND bs."innings_no" = bb."innings_no"
         AND bs."over_id"    = bb."over_id"
         AND bs."ball_id"    = bb."ball_id"
    GROUP BY bs."match_id", bb."striker"
),   

hundreds AS (             -- keep only 100-plus scores
    SELECT *
    FROM player_runs
    WHERE "total_runs" >= 100
),   

hundreds_with_team AS (   -- identify the team for which the player appeared in that match
    SELECT 
        h."match_id",
        h."player_id",
        pm."team_id"
    FROM hundreds h
    JOIN "IPL"."IPL"."PLAYER_MATCH" pm
         ON  h."match_id" = pm."match_id"
         AND h."player_id" = pm."player_id"
),   

lost_team_hundreds AS (   -- retain only those instances where that team lost
    SELECT DISTINCT
        hwt."player_id"
    FROM hundreds_with_team hwt
    JOIN "IPL"."IPL"."MATCH" m
         ON hwt."match_id" = m."match_id"
    WHERE m."match_winner" IS NOT NULL
      AND hwt."team_id" <> m."match_winner"
)

SELECT DISTINCT
       p."player_name"
FROM   lost_team_hundreds lth
JOIN   "IPL"."IPL"."PLAYER" p
       ON lth."player_id" = p."player_id"
ORDER BY p."player_name";