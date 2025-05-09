SELECT
    "country_stats"."country_name" AS "Country",
    ROUND("country_stats"."avg_runs_per_match", 4) AS "Average_Runs_per_Match",
    ROUND("country_stats"."batting_average", 4) AS "Batting_Average"
FROM (
    SELECT
        "p"."country_name",
        SUM("r"."total_runs") * 1.0 / SUM("m"."matches_played") AS "avg_runs_per_match",
        SUM("r"."total_runs") * 1.0 / SUM("o"."dismissals") AS "batting_average"
    FROM (
        SELECT "b"."striker", SUM("bs"."runs_scored") AS "total_runs"
        FROM "ball_by_ball" AS "b"
        JOIN "batsman_scored" AS "bs"
            ON "b"."match_id" = "bs"."match_id"
            AND "b"."over_id" = "bs"."over_id"
            AND "b"."ball_id" = "bs"."ball_id"
            AND "b"."innings_no" = "bs"."innings_no"
        GROUP BY "b"."striker"
    ) AS "r"
    JOIN (
        SELECT "player_id", COUNT(DISTINCT "match_id") AS "matches_played"
        FROM "player_match"
        GROUP BY "player_id"
    ) AS "m"
        ON "r"."striker" = "m"."player_id"
    LEFT JOIN (
        SELECT "player_out", COUNT(*) AS "dismissals"
        FROM "wicket_taken"
        GROUP BY "player_out"
    ) AS "o"
        ON "r"."striker" = "o"."player_out"
    JOIN "player" AS "p"
        ON "r"."striker" = "p"."player_id"
    GROUP BY "p"."country_name"
) AS "country_stats"
ORDER BY "country_stats"."avg_runs_per_match" DESC
LIMIT 5;