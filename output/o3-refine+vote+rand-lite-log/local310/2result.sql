WITH results_with_year AS (
    SELECT r.*, ra."year"
    FROM results r
    JOIN races ra ON ra.race_id = r.race_id
),
driver_year_points AS (
    SELECT "year", driver_id, SUM(points) AS driver_pts
    FROM results_with_year
    GROUP BY "year", driver_id
),
top_driver AS (
    SELECT "year", MAX(driver_pts) AS max_driver_pts
    FROM driver_year_points
    GROUP BY "year"
),
constructor_year_points AS (
    SELECT "year", constructor_id, SUM(points) AS constructor_pts
    FROM results_with_year
    GROUP BY "year", constructor_id
),
top_constructor AS (
    SELECT "year", MAX(constructor_pts) AS max_constructor_pts
    FROM constructor_year_points
    GROUP BY "year"
),
year_totals AS (
    SELECT d."year",
           d.max_driver_pts + c.max_constructor_pts AS combined_top_pts
    FROM top_driver d
    JOIN top_constructor c ON d."year" = c."year"
)
SELECT "year"
FROM year_totals
ORDER BY combined_top_pts ASC, "year" ASC
LIMIT 3;