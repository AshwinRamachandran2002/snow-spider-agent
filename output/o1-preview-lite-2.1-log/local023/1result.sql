SELECT "p"."player_name" AS "Player_Name", 
       ROUND(("runs"."total_runs" * 1.0) / "matches"."matches_played", 4) AS "Batting_Average"
FROM (
    SELECT "bb"."striker" AS "player_id", SUM("bs"."runs_scored") AS "total_runs"
    FROM "ball_by_ball" AS "bb"
    JOIN "batsman_scored" AS "bs"
      ON "bb"."match_id" = "bs"."match_id"
     AND "bb"."over_id" = "bs"."over_id"
     AND "bb"."ball_id" = "bs"."ball_id"
    WHERE "bb"."match_id" IN (
        SELECT "match_id" FROM "match" WHERE "season_id" = 5
    )
    GROUP BY "bb"."striker"
) AS "runs"
JOIN (
    SELECT "player_id", COUNT(DISTINCT "match_id") AS "matches_played"
    FROM "player_match"
    WHERE "match_id" IN (
        SELECT "match_id" FROM "match" WHERE "season_id" = 5
    )
    GROUP BY "player_id"
) AS "matches"
ON "runs"."player_id" = "matches"."player_id"
JOIN "player" AS "p" ON "runs"."player_id" = "p"."player_id"
ORDER BY "Batting_Average" DESC
LIMIT 5;