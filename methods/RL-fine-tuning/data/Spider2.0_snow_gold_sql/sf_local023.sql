WITH season5_matches AS (
    SELECT "match_id"
    FROM IPL.IPL."MATCH"
    WHERE "season_id" = 5
),
player_runs AS (
    SELECT bb."striker" AS "player_id", SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL."BALL_BY_BALL" AS bb
    JOIN IPL.IPL."BATSMAN_SCORED" AS bs
        ON bb."match_id" = bs."match_id" 
        AND bb."over_id" = bs."over_id" 
        AND bb."ball_id" = bs."ball_id"
        AND bb."innings_no" = bs."innings_no"
    WHERE bb."match_id" IN (SELECT "match_id" FROM season5_matches)
    GROUP BY bb."striker"
),
player_matches AS (
    SELECT pm."player_id", COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM IPL.IPL."PLAYER_MATCH" AS pm
    WHERE pm."match_id" IN (SELECT "match_id" FROM season5_matches)
    GROUP BY pm."player_id"
),
player_average AS (
    SELECT pr."player_id", pr."total_runs", pm."matches_played",
           ROUND(pr."total_runs"::NUMERIC / pm."matches_played", 4) AS "average_runs_per_match"
    FROM player_runs AS pr
    JOIN player_matches AS pm
        ON pr."player_id" = pm."player_id"
)
SELECT p."player_name", pa."average_runs_per_match"
FROM player_average AS pa
JOIN IPL.IPL."PLAYER" AS p
    ON pa."player_id" = p."player_id"
ORDER BY pa."average_runs_per_match" DESC NULLS LAST, p."player_name"
LIMIT 5;