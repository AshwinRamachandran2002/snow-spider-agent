WITH "season_matches" AS (
    SELECT "match_id"
    FROM IPL.IPL."MATCH"
    WHERE "season_id" = 5
),
"player_runs" AS (
    SELECT bb."striker" AS "player_id",
           SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL."BATSMAN_SCORED" bs
    JOIN IPL.IPL."BALL_BY_BALL" bb
      ON bs."match_id" = bb."match_id"
     AND bs."innings_no" = bb."innings_no"
     AND bs."over_id" = bb."over_id"
     AND bs."ball_id" = bb."ball_id"
    WHERE bs."match_id" IN (SELECT "match_id" FROM "season_matches")
    GROUP BY bb."striker"
),
"player_matches" AS (
    SELECT pm."player_id",
           COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM IPL.IPL."PLAYER_MATCH" pm
    WHERE pm."match_id" IN (SELECT "match_id" FROM "season_matches")
    GROUP BY pm."player_id"
),
"player_avg" AS (
    SELECT pr."player_id",
           pr."total_runs",
           pm."matches_played",
           pr."total_runs" / pm."matches_played" AS "avg_runs_per_match"
    FROM "player_runs" pr
    JOIN "player_matches" pm
      ON pr."player_id" = pm."player_id"
)
SELECT pl."player_name",
       ROUND(pa."avg_runs_per_match", 4) AS "batting_average"
FROM "player_avg" pa
JOIN IPL.IPL."PLAYER" pl
  ON pa."player_id" = pl."player_id"
ORDER BY "batting_average" DESC NULLS LAST
LIMIT 5;