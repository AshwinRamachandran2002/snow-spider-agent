WITH season5_matches AS (
    SELECT "match_id"
    FROM "match"
    WHERE "season_id" = 5
),
runs_per_match AS (
    SELECT b."match_id",
           b."striker" AS "player_id",
           SUM(s."runs_scored") AS "runs_in_match"
    FROM "ball_by_ball" AS b
    JOIN "batsman_scored" AS s
      ON b."match_id"   = s."match_id"
     AND b."over_id"    = s."over_id"
     AND b."ball_id"    = s."ball_id"
     AND b."innings_no" = s."innings_no"
    WHERE b."match_id" IN (SELECT "match_id" FROM season5_matches)
    GROUP BY b."match_id", b."striker"
),
player_aggregates AS (
    SELECT "player_id",
           SUM("runs_in_match")              AS "total_runs",
           COUNT(DISTINCT "match_id")        AS "matches_played"
    FROM runs_per_match
    GROUP BY "player_id"
)
SELECT p."player_name",
       ROUND(pa."total_runs" * 1.0 / pa."matches_played", 4) AS "batting_average"
FROM player_aggregates AS pa
JOIN "player" AS p
  ON p."player_id" = pa."player_id"
ORDER BY "batting_average" DESC
LIMIT 5;