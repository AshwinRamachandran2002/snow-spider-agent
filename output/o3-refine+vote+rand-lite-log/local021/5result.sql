WITH player_match_runs AS (
    SELECT 
        b."match_id",
        bb."striker" AS player_id,
        SUM(b."runs_scored") AS total_runs
    FROM "batsman_scored" b
    JOIN "ball_by_ball" bb
      ON bb."match_id" = b."match_id"
     AND bb."over_id"  = b."over_id"
     AND bb."ball_id"  = b."ball_id"
     AND bb."innings_no" = b."innings_no"
    GROUP BY b."match_id", bb."striker"
),
above_50 AS (
    SELECT total_runs
    FROM player_match_runs
    WHERE total_runs > 50
)
SELECT ROUND(AVG(total_runs), 4) AS average_runs_above_50
FROM above_50;