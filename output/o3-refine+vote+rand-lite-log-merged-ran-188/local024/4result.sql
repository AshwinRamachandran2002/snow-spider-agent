WITH player_runs_per_match AS (
    -- total runs each player scores in every match he/she appeared
    SELECT
        b."match_id",
        b."striker"      AS player_id,
        SUM(bs."runs_scored") AS runs_in_match
    FROM "ball_by_ball"  b
    JOIN "batsman_scored" bs
         ON bs."match_id"   = b."match_id"
        AND bs."over_id"    = b."over_id"
        AND bs."ball_id"    = b."ball_id"
        AND bs."innings_no" = b."innings_no"
    GROUP BY b."match_id", b."striker"
),
player_avg AS (
    -- average runs per match for every player
    SELECT
        player_id,
        AVG(runs_in_match * 1.0) AS avg_runs_per_match
    FROM player_runs_per_match
    GROUP BY player_id
)
-- country‑wise average of those player averages, choose top 5
SELECT
    p."country_name",
    ROUND(AVG(pa.avg_runs_per_match), 4) AS country_batting_avg
FROM player_avg pa
JOIN "player" p
     ON p."player_id" = pa."player_id"
GROUP BY p."country_name"
ORDER BY country_batting_avg DESC, p."country_name"
LIMIT 5;