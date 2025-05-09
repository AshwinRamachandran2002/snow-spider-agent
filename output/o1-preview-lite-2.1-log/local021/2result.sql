SELECT AVG("average_runs") AS "Average_Total_Score"
FROM (
  SELECT "striker", AVG("total_runs") AS "average_runs"
  FROM (
    SELECT "bb"."striker", "bb"."match_id", SUM("bs"."runs_scored") AS "total_runs"
    FROM "ball_by_ball" AS "bb"
    INNER JOIN "batsman_scored" AS "bs"
      ON "bb"."match_id" = "bs"."match_id"
      AND "bb"."over_id" = "bs"."over_id"
      AND "bb"."ball_id" = "bs"."ball_id"
      AND "bb"."innings_no" = "bs"."innings_no"
    GROUP BY "bb"."striker", "bb"."match_id"
  ) AS "total_runs_per_match"
  WHERE "striker" IN (
    SELECT DISTINCT "striker"
    FROM (
      SELECT "bb"."striker", SUM("bs"."runs_scored") AS "total_runs"
      FROM "ball_by_ball" AS "bb"
      INNER JOIN "batsman_scored" AS "bs"
        ON "bb"."match_id" = "bs"."match_id"
        AND "bb"."over_id" = "bs"."over_id"
        AND "bb"."ball_id" = "bs"."ball_id"
        AND "bb"."innings_no" = "bs"."innings_no"
      GROUP BY "bb"."striker", "bb"."match_id"
      HAVING SUM("bs"."runs_scored") > 50
    ) AS "strikers_over_50"
  )
  GROUP BY "striker"
) AS "average_runs_per_striker";