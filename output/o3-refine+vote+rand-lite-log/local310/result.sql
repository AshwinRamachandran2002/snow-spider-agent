WITH driver_year_points AS (
    SELECT ra.year,
           r.driver_id,
           SUM(r.points) AS driver_points
    FROM results r
    JOIN races  ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.driver_id
),
max_driver_year AS (
    SELECT year,
           MAX(driver_points) AS max_driver_points
    FROM driver_year_points
    GROUP BY year
),
constructor_year_points AS (
    SELECT ra.year,
           r.constructor_id,
           SUM(r.points) AS constructor_points
    FROM results r
    JOIN races ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.constructor_id
),
max_constructor_year AS (
    SELECT year,
           MAX(constructor_points) AS max_constructor_points
    FROM constructor_year_points
    GROUP BY year
),
year_totals AS (
    SELECT d.year,
           d.max_driver_points + c.max_constructor_points AS total_points
    FROM max_driver_year       d
    JOIN max_constructor_year  c ON c.year = d.year
)
SELECT year
FROM year_totals
ORDER BY total_points ASC, year ASC
LIMIT 3;