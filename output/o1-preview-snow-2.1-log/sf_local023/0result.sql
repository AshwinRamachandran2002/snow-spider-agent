SELECT
    p."player_name" AS "Player_Name",
    ROUND((r."total_runs" * 1.0) / m."matches_played", 4) AS "Batting_Average"
FROM (
    SELECT
        bb."striker" AS "player_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM "IPL"."IPL"."BATSMAN_SCORED" bs
    JOIN "IPL"."IPL"."BALL_BY_BALL" bb
        ON bs."match_id" = bb."match_id"
        AND bs."over_id" = bb."over_id"
        AND bs."ball_id" = bb."ball_id"
        AND bs."innings_no" = bb."innings_no"
    JOIN "IPL"."IPL"."MATCH" m
        ON bs."match_id" = m."match_id"
    WHERE m."season_id" = 5
    GROUP BY bb."striker"
) r
JOIN (
    SELECT
        pm."player_id",
        COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM "IPL"."IPL"."PLAYER_MATCH" pm
    JOIN "IPL"."IPL"."MATCH" m
        ON pm."match_id" = m."match_id"
    WHERE m."season_id" = 5
    GROUP BY pm."player_id"
) m ON r."player_id" = m."player_id"
JOIN "IPL"."IPL"."PLAYER" p ON r."player_id" = p."player_id"
ORDER BY "Batting_Average" DESC NULLS LAST
LIMIT 5;