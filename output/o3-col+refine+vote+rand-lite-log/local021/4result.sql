SELECT ROUND(AVG(t."total_runs"), 4) AS "average_runs_for_50plus"
FROM (
    SELECT 
        b."match_id",
        b."striker",
        SUM(s."runs_scored") AS "total_runs"
    FROM "ball_by_ball" AS b
    JOIN "batsman_scored" AS s
      ON b."match_id" = s."match_id"
     AND b."over_id"  = s."over_id"
     AND b."ball_id"  = s."ball_id"
    GROUP BY b."match_id", b."striker"
    HAVING SUM(s."runs_scored") > 50
) AS t;