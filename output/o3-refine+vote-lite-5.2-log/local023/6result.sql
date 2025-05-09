WITH season_matches AS (
    SELECT "match_id"
    FROM "match"
    WHERE "season_id" = 5
),
player_runs AS (
    SELECT
        b."striker" AS player_id,
        SUM(s."runs_scored") AS total_runs
    FROM season_matches sm
    JOIN "ball_by_ball" b
        ON b."match_id" = sm."match_id"
    JOIN "batsman_scored" s
        ON s."match_id"  = b."match_id"
       AND s."over_id"   = b."over_id"
       AND s."ball_id"   = b."ball_id"
       AND s."innings_no"= b."innings_no"
    GROUP BY b."striker"
),
player_matches AS (
    SELECT
        pm."player_id",
        COUNT(DISTINCT pm."match_id") AS matches_played
    FROM "player_match" pm
    JOIN season_matches sm
        ON sm."match_id" = pm."match_id"
    GROUP BY pm."player_id"
),
player_avg AS (
    SELECT
        pr.player_id,
        pr.total_runs,
        pm.matches_played,
        1.0 * pr.total_runs / pm.matches_played AS avg_runs_per_match
    FROM player_runs   pr
    JOIN player_matches pm
      ON pm.player_id = pr.player_id
)
SELECT
    p."player_name",
    ROUND(pa.avg_runs_per_match, 4) AS batting_average
FROM player_avg pa
JOIN "player" p
  ON p."player_id" = pa.player_id
ORDER BY
    pa.avg_runs_per_match DESC,
    p."player_name" ASC
LIMIT 5;