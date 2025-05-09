/*  Top 5 players with the highest average runs per match in season 5  */
WITH "season_matches" AS (               -- all matches that belong to season 5
    SELECT "match_id"
    FROM IPL.IPL."MATCH"
    WHERE "season_id" = 5
),
"player_runs" AS (                       -- total runs scored by every striker in season-5
    SELECT 
        bb."striker"                     AS "player_id",
        SUM(bs."runs_scored")            AS "total_runs"
    FROM IPL.IPL."BATSMAN_SCORED" bs
    JOIN IPL.IPL."BALL_BY_BALL"  bb
         ON  bs."match_id"   = bb."match_id"
         AND bs."innings_no" = bb."innings_no"
         AND bs."over_id"    = bb."over_id"
         AND bs."ball_id"    = bb."ball_id"
    JOIN "season_matches" sm
         ON bs."match_id" = sm."match_id"
    GROUP BY bb."striker"
),
"player_matches" AS (                    -- number of season-5 matches each player appeared in
    SELECT
        pm."player_id",
        COUNT(DISTINCT pm."match_id")    AS "matches_played"
    FROM IPL.IPL."PLAYER_MATCH" pm
    JOIN "season_matches" sm
         ON pm."match_id" = sm."match_id"
    GROUP BY pm."player_id"
),
"averages" AS (                          -- compute average runs per match
    SELECT
        pr."player_id",
        pr."total_runs",
        pm."matches_played",
        pr."total_runs" * 1.0 / pm."matches_played"  AS "avg_runs"
    FROM "player_runs"    pr
    JOIN "player_matches" pm
         ON pr."player_id" = pm."player_id"
)
SELECT
    pl."player_name",
    ROUND(av."avg_runs", 4)  AS "batting_average"
FROM "averages"  av
JOIN IPL.IPL."PLAYER" pl
     ON av."player_id" = pl."player_id"
ORDER BY "batting_average" DESC NULLS LAST
LIMIT 5;