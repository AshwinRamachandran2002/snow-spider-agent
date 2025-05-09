SELECT p."player_name", ROUND((t1."total_runs" * 1.0) / t2."matches_played", 4) AS "Batting_Average"
FROM (
    SELECT bbb."striker" AS "player_id", SUM(bbs."runs_scored") AS "total_runs"
    FROM "batsman_scored" bbs
    JOIN "ball_by_ball" bbb
      ON bbs."match_id" = bbb."match_id"
     AND bbs."over_id" = bbb."over_id"
     AND bbs."ball_id" = bbb."ball_id"
     AND bbs."innings_no" = bbb."innings_no"
    WHERE bbs."match_id" IN (
        SELECT "match_id"
        FROM "match"
        WHERE "season_id" = 5
    )
    GROUP BY bbb."striker"
) t1
JOIN (
    SELECT pm."player_id", COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM "player_match" pm
    JOIN "match" m ON pm."match_id" = m."match_id"
    WHERE m."season_id" = 5
    GROUP BY pm."player_id"
) t2 ON t1."player_id" = t2."player_id"
JOIN "player" p ON t1."player_id" = p."player_id"
ORDER BY "Batting_Average" DESC
LIMIT 5;