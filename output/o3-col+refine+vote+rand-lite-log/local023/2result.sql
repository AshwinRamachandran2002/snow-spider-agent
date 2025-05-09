SELECT
    p."player_name",
    ROUND(r."total_runs" * 1.0 / mp."matches_played", 4) AS "batting_average"
FROM (
    SELECT
        bb."striker" AS "player_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM "ball_by_ball" AS bb
    JOIN "batsman_scored" AS bs
      ON bs."match_id"  = bb."match_id"
     AND bs."over_id"   = bb."over_id"
     AND bs."ball_id"   = bb."ball_id"
     AND bs."innings_no"= bb."innings_no"
    JOIN "match" AS m
      ON m."match_id" = bb."match_id"
    WHERE m."season_id" = 5
    GROUP BY bb."striker"
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
ORDER BY "batting_average" DESC
LIMIT 5;