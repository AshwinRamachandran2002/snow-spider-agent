WITH season5_matches AS (
    SELECT "match_id"
    FROM "match"
    WHERE "season_id" = 5
),
total_runs AS (
    SELECT bb."striker" AS "player_id",
           SUM(bs."runs_scored") AS "total_runs"
    FROM "ball_by_ball"  AS bb
    JOIN "batsman_scored" AS bs
      ON bb."match_id"   = bs."match_id"
     AND bb."over_id"    = bs."over_id"
     AND bb."ball_id"    = bs."ball_id"
     AND bb."innings_no" = bs."innings_no"
    WHERE bb."match_id" IN (SELECT "match_id" FROM season5_matches)
    GROUP BY bb."striker"
),
matches_played AS (
    SELECT pm."player_id",
           COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM "player_match" AS pm
    WHERE pm."match_id" IN (SELECT "match_id" FROM season5_matches)
    GROUP BY pm."player_id"
),
averages AS (
    SELECT tr."player_id",
           1.0 * tr."total_runs" / mp."matches_played" AS "batting_average"
    FROM total_runs  AS tr
    JOIN matches_played AS mp
      ON tr."player_id" = mp."player_id"
)
SELECT p."player_name",
       ROUND(a."batting_average", 4) AS "batting_average"
FROM averages AS a
JOIN "player" AS p
  ON p."player_id" = a."player_id"
ORDER BY a."batting_average" DESC
LIMIT 5;