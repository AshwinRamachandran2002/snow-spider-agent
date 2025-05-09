WITH driver_year AS (
    SELECT r."year",
           res."driver_id",
           SUM(res."points") AS driver_points
    FROM   "results" AS res
    JOIN   "races"   AS r USING ("race_id")
    GROUP  BY r."year", res."driver_id"
),
max_driver AS (
    SELECT "year",
           MAX(driver_points) AS max_driver_pts
    FROM   driver_year
    GROUP  BY "year"
),
constructor_year AS (
    SELECT r."year",
           res."constructor_id",
           SUM(res."points") AS constructor_points
    FROM   "results" AS res
    JOIN   "races"   AS r USING ("race_id")
    GROUP  BY r."year", res."constructor_id"
),
max_constructor AS (
    SELECT "year",
           MAX(constructor_points) AS max_constructor_pts
    FROM   constructor_year
    GROUP  BY "year"
),
combined AS (
    SELECT d."year",
           d.max_driver_pts + c.max_constructor_pts AS total_pts
    FROM   max_driver      AS d
    JOIN   max_constructor AS c USING ("year")
)
SELECT "year"
FROM   combined
ORDER  BY total_pts ASC, "year" ASC
LIMIT 3;