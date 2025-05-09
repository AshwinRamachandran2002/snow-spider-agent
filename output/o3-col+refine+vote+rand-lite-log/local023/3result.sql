WITH per_match AS (
    SELECT bb."match_id",
           bb."striker"          AS "player_id",
           SUM(bs."runs_scored") AS "runs_in_match"
    FROM "ball_by_ball"  AS bb
    JOIN "batsman_scored" AS bs USING ("match_id","over_id","ball_id")
    JOIN "match"          AS m  ON m."match_id" = bb."match_id"
    WHERE m."season_id" = 5
    GROUP BY bb."match_id", bb."striker"
),
season_totals AS (
    SELECT "player_id",
           SUM("runs_in_match")           AS "total_runs",
           COUNT(*)                       AS "matches_played"
    FROM per_match
    GROUP BY "player_id"
)
SELECT p."player_name",
       printf('%.2f', 1.0 * st."total_runs" / st."matches_played") AS "batting_average"
FROM season_totals st
JOIN "player" p ON p."player_id" = st."player_id"
ORDER BY 1.0 * st."total_runs" / st."matches_played" DESC
LIMIT 5;