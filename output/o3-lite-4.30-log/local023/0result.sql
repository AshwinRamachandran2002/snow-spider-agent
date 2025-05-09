SELECT
    p."player_name",
    printf('%.4f', 1.0 * r."total_runs" / mp."matches_played") AS "batting_average"
FROM (
        SELECT
            b."striker" AS "player_id",
            SUM(bs."runs_scored") AS "total_runs"
        FROM "ball_by_ball" AS b
        JOIN "batsman_scored" AS bs
          ON bs."match_id" = b."match_id"
         AND bs."over_id"  = b."over_id"
         AND bs."ball_id"  = b."ball_id"
        JOIN "match" AS m
          ON m."match_id" = b."match_id"
        WHERE m."season_id" = 5
        GROUP BY b."striker"
     ) AS r
JOIN (
        SELECT
            pm."player_id",
            COUNT(DISTINCT pm."match_id") AS "matches_played"
        FROM "player_match" AS pm
        JOIN "match" AS m
          ON m."match_id" = pm."match_id"
        WHERE m."season_id" = 5
        GROUP BY pm."player_id"
     ) AS mp
  ON mp."player_id" = r."player_id"
JOIN "player" AS p
  ON p."player_id" = r."player_id"
ORDER BY CAST("batting_average" AS REAL) DESC, p."player_name"
LIMIT 5;