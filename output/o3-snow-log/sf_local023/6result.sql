WITH "SEASON_MATCHES" AS (
    SELECT "match_id"
    FROM IPL.IPL."MATCH"
    WHERE "season_id" = 5
),  
"BALLS" AS (         -- balls of Season-5 with striker and runs
    SELECT
        bb."match_id",
        bb."striker"          AS "player_id",
        bs."runs_scored"
    FROM IPL.IPL."BALL_BY_BALL"   bb
    JOIN IPL.IPL."BATSMAN_SCORED" bs
          ON  bb."match_id"   = bs."match_id"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
          AND bb."innings_no" = bs."innings_no"
    JOIN "SEASON_MATCHES" sm
          ON bb."match_id" = sm."match_id"
),  
"PLAYER_RUNS" AS (   -- total runs per player in Season-5
    SELECT
        "player_id",
        SUM("runs_scored") AS "total_runs"
    FROM "BALLS"
    GROUP BY "player_id"
),  
"PLAYER_MATCHES" AS ( -- number of matches each player appeared in Season-5
    SELECT
        pm."player_id",
        COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM IPL.IPL."PLAYER_MATCH" pm
    JOIN "SEASON_MATCHES" sm
          ON pm."match_id" = sm."match_id"
    GROUP BY pm."player_id"
),  
"PLAYER_AVG" AS (    -- average runs per match
    SELECT
        pr."player_id",
        pr."total_runs",
        pm."matches_played",
        pr."total_runs" / pm."matches_played" AS "avg_runs_per_match"
    FROM "PLAYER_RUNS"    pr
    JOIN "PLAYER_MATCHES" pm
          ON pr."player_id" = pm."player_id"
),  
"TOP5" AS (          -- top 5 players by average
    SELECT *
    FROM "PLAYER_AVG"
    ORDER BY "avg_runs_per_match" DESC NULLS LAST
    LIMIT 5
)
SELECT
    pl."player_name",
    ROUND(t."avg_runs_per_match", 4) AS "batting_average"
FROM "TOP5" t
JOIN IPL.IPL."PLAYER" pl
      ON pl."player_id" = t."player_id"
ORDER BY "batting_average" DESC NULLS LAST;