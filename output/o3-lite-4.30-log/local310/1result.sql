WITH driver_totals AS (
    SELECT r."year" AS year,
           res."driver_id",
           SUM(res."points") AS driver_pts
    FROM "results" res
    JOIN "races"  r ON r."race_id" = res."race_id"
    GROUP BY r."year", res."driver_id"
),
best_driver AS (
    SELECT year,
           MAX(driver_pts) AS max_driver_pts
    FROM driver_totals
    GROUP BY year
),
constructor_totals AS (
    SELECT r."year" AS year,
           res."constructor_id",
           SUM(res."points") AS constructor_pts
    FROM "results" res
    JOIN "races"  r ON r."race_id" = res."race_id"
    GROUP BY r."year", res."constructor_id"
),
best_constructor AS (
    SELECT year,
           MAX(constructor_pts) AS max_constructor_pts
    FROM constructor_totals
    GROUP BY year
),
combined AS (
    SELECT d.year,
           d.max_driver_pts + c.max_constructor_pts AS total_points
    FROM best_driver      d
    JOIN best_constructor c
      ON c.year = d.year
)
SELECT year,
       ROUND(total_points, 4) AS total_points
FROM combined
ORDER BY total_points ASC, year ASC
LIMIT 3;