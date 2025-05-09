WITH fifty_plus AS (
    -- Strikers who have scored more than 50 in at least one match
    SELECT b."striker" AS "player_id"
    FROM "ball_by_ball"  AS b
    JOIN "batsman_scored" AS s
      ON b."match_id"   = s."match_id"
     AND b."over_id"    = s."over_id"
     AND b."ball_id"    = s."ball_id"
     AND b."innings_no" = s."innings_no"
    GROUP BY b."match_id", b."striker"
    HAVING SUM(s."runs_scored") > 50
),
career_runs AS (
    -- Total (career) runs for each of those strikers
    SELECT b."striker"              AS "player_id",
           SUM(s."runs_scored")     AS "total_runs"
    FROM "ball_by_ball"  AS b
    JOIN "batsman_scored" AS s
      ON b."match_id"   = s."match_id"
     AND b."over_id"    = s."over_id"
     AND b."ball_id"    = s."ball_id"
     AND b."innings_no" = s."innings_no"
    WHERE b."striker" IN (SELECT "player_id" FROM fifty_plus)
    GROUP BY b."striker"
)
-- Average of those total‐run tallies (rounded to 4 decimal places)
SELECT ROUND(AVG("total_runs"), 4) AS "average_total_runs"
FROM career_runs;