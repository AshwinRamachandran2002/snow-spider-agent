WITH player_runs AS (        -- runs scored by every batsman in every match
    SELECT
        bb."match_id",
        bb."striker"                         AS "player_id",
        SUM(bs."runs_scored")                AS "total_runs"
    FROM  "IPL"."IPL"."BATSMAN_SCORED" bs
    JOIN  "IPL"."IPL"."BALL_BY_BALL"   bb
          ON  bb."match_id"    = bs."match_id"
          AND bb."innings_no"  = bs."innings_no"
          AND bb."over_id"     = bs."over_id"
          AND bb."ball_id"     = bs."ball_id"
    GROUP BY
        bb."match_id",
        bb."striker"
    HAVING
        SUM(bs."runs_scored") >= 100         -- at least 100 runs in the match
),

player_team AS (                             -- team for which each player appeared in that match
    SELECT DISTINCT
        "match_id",
        "player_id",
        "team_id"
    FROM "IPL"."IPL"."PLAYER_MATCH"
),

eligible AS (                                -- 100-plus scores made for the losing side
    SELECT
        pr."player_id",
        pr."match_id",
        pt."team_id"
    FROM  player_runs               pr
    JOIN  player_team               pt  ON pt."match_id" = pr."match_id"
                                        AND pt."player_id" = pr."player_id"
    JOIN  "IPL"."IPL"."MATCH"       m   ON m."match_id"    = pr."match_id"
    WHERE m."match_winner" IS NOT NULL            -- completed matches
      AND pt."team_id" <> m."match_winner"        -- player’s team lost
)

SELECT DISTINCT
       p."player_name"
FROM   eligible e
JOIN   "IPL"."IPL"."PLAYER" p ON p."player_id" = e."player_id"
ORDER BY p."player_name";