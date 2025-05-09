WITH season_matches AS (
    SELECT "match_id"
    FROM "match"
    WHERE "season_id" = 5
),
player_runs_per_match AS (
    /* total runs each player scored in each season‑5 match */
    SELECT
        pm."player_id",
        pm."match_id",
        SUM(COALESCE(bs."runs_scored", 0)) AS runs_in_match
    FROM "player_match" pm
    JOIN season_matches sm
         ON sm."match_id" = pm."match_id"
    LEFT JOIN "ball_by_ball" bb
         ON bb."match_id" = pm."match_id"
        AND bb."striker"  = pm."player_id"
    LEFT JOIN "batsman_scored" bs
         ON bs."match_id"   = bb."match_id"
        AND bs."over_id"    = bb."over_id"
        AND bs."ball_id"    = bb."ball_id"
        AND bs."innings_no" = bb."innings_no"
    GROUP BY pm."player_id", pm."match_id"
),
player_average AS (
    /* average runs per match for each player in season 5 */
    SELECT
        "player_id",
        AVG(runs_in_match * 1.0) AS avg_runs
    FROM player_runs_per_match
    GROUP BY "player_id"
)
SELECT
    p."player_name",
    ROUND(pa.avg_runs, 4) AS batting_average
FROM player_average pa
JOIN "player" p
  ON p."player_id" = pa."player_id"
ORDER BY pa.avg_runs DESC, p."player_name"
LIMIT 5;