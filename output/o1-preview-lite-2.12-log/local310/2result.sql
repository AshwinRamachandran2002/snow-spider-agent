SELECT "year", ROUND("total_points", 4) AS "Total_Points"
FROM (
  SELECT
    "driver_max"."year",
    ("driver_max"."max_driver_points" + "constructor_max"."max_constructor_points") AS "total_points"
  FROM (
    SELECT "year", MAX("total_points") AS "max_driver_points"
    FROM (
      SELECT "r"."year", "res"."driver_id", SUM("res"."points") AS "total_points"
      FROM "results" AS "res"
      JOIN "races" AS "r" ON "res"."race_id" = "r"."race_id"
      GROUP BY "r"."year", "res"."driver_id"
    ) AS "driver_totals"
    GROUP BY "year"
  ) AS "driver_max"
  JOIN (
    SELECT "year", MAX("total_points") AS "max_constructor_points"
    FROM (
      SELECT "r"."year", "res"."constructor_id", SUM("res"."points") AS "total_points"
      FROM "results" AS "res"
      JOIN "races" AS "r" ON "res"."race_id" = "r"."race_id"
      GROUP BY "r"."year", "res"."constructor_id"
    ) AS "constructor_totals"
    GROUP BY "year"
  ) AS "constructor_max" ON "driver_max"."year" = "constructor_max"."year"
) AS "year_totals"
ORDER BY "total_points" ASC
LIMIT 3;