WITH driver_max_points AS (
    SELECT "race_id", MAX("driver_total_points") AS "max_driver_points"
    FROM (
        SELECT "race_id", "driver_id", SUM("points") AS "driver_total_points"
        FROM "F1"."F1"."RESULTS"
        GROUP BY "race_id", "driver_id"
    ) AS driver_points_per_race
    GROUP BY "race_id"
),
constructor_max_points AS (
    SELECT "race_id", MAX("constructor_total_points") AS "max_constructor_points"
    FROM (
        SELECT "race_id", "constructor_id", SUM("points") AS "constructor_total_points"
        FROM "F1"."F1"."RESULTS"
        GROUP BY "race_id", "constructor_id"
    ) AS constructor_points_per_race
    GROUP BY "race_id"
)
SELECT d."race_id",
       d."max_driver_points",
       c."max_constructor_points",
       d."max_driver_points" + c."max_constructor_points" AS "total"
FROM driver_max_points d
JOIN constructor_max_points c ON d."race_id" = c."race_id"
ORDER BY "total" ASC NULLS LAST
LIMIT 3;