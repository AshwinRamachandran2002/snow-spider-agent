WITH driver_totals AS (
    SELECT r."year",
           res."driver_id",
           SUM(res."points") AS driver_points
    FROM   "results" AS res
    JOIN   "races"   AS r ON r."race_id" = res."race_id"
    GROUP  BY r."year", res."driver_id"
),
driver_max AS (
    SELECT "year",
           MAX(driver_points) AS max_driver_points
    FROM   driver_totals
    GROUP  BY "year"
),
constructor_totals AS (
    SELECT r."year",
           res."constructor_id",
           SUM(res."points") AS constructor_points
    FROM   "results" AS res
    JOIN   "races"   AS r ON r."race_id" = res."race_id"
    GROUP  BY r."year", res."constructor_id"
),
constructor_max AS (
    SELECT "year",
           MAX(constructor_points) AS max_constructor_points
    FROM   constructor_totals
    GROUP  BY "year"
),
combined AS (
    SELECT d."year",
           d.max_driver_points + c.max_constructor_points AS combined_points
    FROM   driver_max      AS d
    JOIN   constructor_max AS c USING ("year")
)
SELECT "year"
FROM   combined
ORDER  BY combined_points ASC, "year" ASC
LIMIT 3;