SELECT DISTINCT "p"."player_name"
FROM (
    SELECT "b"."match_id", "b"."striker", SUM("bs"."runs_scored") AS "total_runs"
    FROM "ball_by_ball" AS "b"
    JOIN "batsman_scored" AS "bs" ON
        "b"."match_id" = "bs"."match_id" AND
        "b"."innings_no" = "bs"."innings_no" AND
        "b"."over_id" = "bs"."over_id" AND
        "b"."ball_id" = "bs"."ball_id"
    GROUP BY "b"."match_id", "b"."striker"
    HAVING SUM("bs"."runs_scored") >= 100
) AS "t"
JOIN "player_match" AS "pm" ON "t"."match_id" = "pm"."match_id" AND "t"."striker" = "pm"."player_id"
JOIN "match" AS "m" ON "t"."match_id" = "m"."match_id"
JOIN "player" AS "p" ON "t"."striker" = "p"."player_id"
WHERE "pm"."team_id" != "m"."match_winner";