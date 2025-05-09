SELECT AVG(sub.total_runs) AS "Average_Total_Score"
FROM (
    SELECT b."striker", b."match_id", SUM(s."runs_scored") AS total_runs
    FROM "ball_by_ball" AS b
    JOIN "batsman_scored" AS s
      ON b."match_id" = s."match_id"
      AND b."over_id" = s."over_id"
      AND b."ball_id" = s."ball_id"
      AND b."innings_no" = s."innings_no"
    GROUP BY b."striker", b."match_id"
) AS sub
WHERE sub."striker" IN (
    SELECT DISTINCT t."striker"
    FROM (
        SELECT b."striker", SUM(s."runs_scored") AS total_runs
        FROM "ball_by_ball" AS b
        JOIN "batsman_scored" AS s
          ON b."match_id" = s."match_id"
          AND b."over_id" = s."over_id"
          AND b."ball_id" = s."ball_id"
          AND b."innings_no" = s."innings_no"
        GROUP BY b."striker", b."match_id"
        HAVING total_runs > 50
    ) AS t
)
;