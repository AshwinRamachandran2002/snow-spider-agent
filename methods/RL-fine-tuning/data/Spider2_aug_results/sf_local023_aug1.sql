-- Task: Please help me find the total runs scored by each player in season 5.
WITH season5_matches AS (
    SELECT "match_id"
    FROM IPL.IPL."MATCH"
    WHERE "season_id" = 5
)
SELECT p."player_name", pr."total_runs"
FROM (
    SELECT bb."striker" AS "player_id", SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL."BALL_BY_BALL" AS bb
    JOIN IPL.IPL."BATSMAN_SCORED" AS bs
        ON bb."match_id" = bs."match_id" 
        AND bb."over_id" = bs."over_id" 
        AND bb."ball_id" = bs."ball_id"
        AND bb."innings_no" = bs."innings_no"
    WHERE bb."match_id" IN (SELECT "match_id" FROM season5_matches)
    GROUP BY bb."striker"
) AS pr
JOIN IPL.IPL."PLAYER" AS p
    ON pr."player_id" = p."player_id"
ORDER BY pr."total_runs" DESC;