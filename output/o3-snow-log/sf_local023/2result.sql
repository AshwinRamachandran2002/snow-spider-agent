WITH "matches_s5" AS (
    SELECT "match_id"
    FROM IPL.IPL.MATCH
    WHERE "season_id" = 5
),
"player_matches_s5" AS (
    SELECT DISTINCT pm."player_id",
           pm."match_id"
    FROM IPL.IPL.PLAYER_MATCH pm
    JOIN "matches_s5" m
      ON pm."match_id" = m."match_id"
),
"matches_played" AS (
    SELECT "player_id",
           COUNT(DISTINCT "match_id") AS "matches_played"
    FROM "player_matches_s5"
    GROUP BY "player_id"
),
"runs_per_player" AS (
    SELECT bb."striker" AS "player_id",
           SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL.BATSMAN_SCORED bs
    JOIN IPL.IPL.BALL_BY_BALL bb
      ON bs."match_id"   = bb."match_id"
     AND bs."innings_no" = bb."innings_no"
     AND bs."over_id"    = bb."over_id"
     AND bs."ball_id"    = bb."ball_id"
    JOIN "matches_s5" m
      ON bs."match_id" = m."match_id"
    GROUP BY bb."striker"
),
"averages" AS (
    SELECT mp."player_id",
           COALESCE(rp."total_runs", 0)                         AS "total_runs",
           mp."matches_played",
           COALESCE(rp."total_runs", 0) / mp."matches_played"::FLOAT AS "avg_runs_per_match"
    FROM "matches_played" mp
    LEFT JOIN "runs_per_player" rp
      ON mp."player_id" = rp."player_id"
)
SELECT p."player_name",
       ROUND(a."avg_runs_per_match", 4) AS "batting_average"
FROM "averages" a
JOIN IPL.IPL.PLAYER p
  ON a."player_id" = p."player_id"
ORDER BY a."avg_runs_per_match" DESC NULLS LAST
FETCH FIRST 5 ROWS;