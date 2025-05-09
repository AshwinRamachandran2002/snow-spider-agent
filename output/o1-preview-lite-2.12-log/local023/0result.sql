SELECT p."player_name", t."batting_average"
FROM (
    SELECT tr."player_id", ROUND((tr."total_runs" * 1.0) / mp."matches_played", 4) AS "batting_average"
    FROM (
        SELECT bbb."striker" AS "player_id", SUM(bs."runs_scored") AS "total_runs"
        FROM "ball_by_ball" AS bbb
        JOIN "batsman_scored" AS bs ON
            bbb."match_id" = bs."match_id" AND
            bbb."over_id" = bs."over_id" AND
            bbb."ball_id" = bs."ball_id" AND
            bbb."innings_no" = bs."innings_no"
        WHERE bbb."match_id" IN (
            SELECT "match_id" FROM "match" WHERE "season_id" = 5
        )
        GROUP BY bbb."striker"
    ) AS tr
    JOIN (
        SELECT "player_id", COUNT(DISTINCT "match_id") AS "matches_played"
        FROM "player_match"
        WHERE "match_id" IN (
            SELECT "match_id" FROM "match" WHERE "season_id" = 5
        )
        GROUP BY "player_id"
    ) AS mp ON tr."player_id" = mp."player_id"
) AS t
JOIN "player" AS p ON t."player_id" = p."player_id"
ORDER BY t."batting_average" DESC
LIMIT 5;