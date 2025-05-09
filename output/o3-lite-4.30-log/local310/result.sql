WITH driver_totals AS (
    SELECT ra."year",
           re."driver_id",
           SUM(re."points") AS driver_pts
    FROM "results" AS re
    JOIN "races"   AS ra ON ra."race_id" = re."race_id"
    GROUP BY ra."year", re."driver_id"
),
top_driver AS (
    SELECT "year",
           MAX(driver_pts) AS top_driver_pts
    FROM driver_totals
    GROUP BY "year"
),
constructor_totals AS (
    SELECT ra."year",
           re."constructor_id",
           SUM(re."points") AS constructor_pts
    FROM "results" AS re
    JOIN "races"   AS ra ON ra."race_id" = re."race_id"
    GROUP BY ra."year", re."constructor_id"
),
top_constructor AS (
    SELECT "year",
           MAX(constructor_pts) AS top_constructor_pts
    FROM constructor_totals
    GROUP BY "year"
),
yearly_sum AS (
    SELECT d."year",
           d.top_driver_pts + c.top_constructor_pts AS total_points
    FROM top_driver      AS d
    JOIN top_constructor AS c ON c."year" = d."year"
)
SELECT "year",
       ROUND(total_points, 4) AS total_points
FROM yearly_sum
ORDER BY total_points ASC, "year"
LIMIT 3;