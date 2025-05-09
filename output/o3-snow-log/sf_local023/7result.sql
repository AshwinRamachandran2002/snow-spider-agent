WITH "matches_s5" AS (
    SELECT "match_id"
    FROM IPL.IPL.MATCH
    WHERE "season_id" = 5
),
"runs_per_player" AS (
    SELECT
        bb."striker"          AS "player_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL.BATSMAN_SCORED bs
    JOIN IPL.IPL.BALL_BY_BALL bb
      ON bs."match_id"   = bb."match_id"
     AND bs."over_id"    = bb."over_id"
     AND bs."ball_id"    = bb."ball_id"
     AND bs."innings_no" = bb."innings_no"
    JOIN "matches_s5" ms
      ON bs."match_id" = ms."match_id"
    GROUP BY bb."striker"
),
"matches_per_player" AS (
    SELECT
        pm."player_id",
        COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM IPL.IPL.PLAYER_MATCH pm
    JOIN "matches_s5" ms
      ON pm."match_id" = ms."match_id"
    GROUP BY pm."player_id"
),
"player_avg" AS (
    SELECT
        rp."player_id",
        rp."total_runs",
        mp."matches_played",
        rp."total_runs" / mp."matches_played" AS "avg_runs_per_match"
    FROM "runs_per_player"  rp
    JOIN "matches_per_player" mp
      ON rp."player_id" = mp."player_id"
)
SELECT
    pl."player_name",
    ROUND(pa."avg_runs_per_match", 4) AS "batting_average"
FROM "player_avg" pa
JOIN IPL.IPL.PLAYER pl
  ON pa."player_id" = pl."player_id"
ORDER BY "batting_average" DESC NULLS LAST
LIMIT 5;