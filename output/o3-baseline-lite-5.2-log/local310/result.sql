WITH driver_year_points AS (
    SELECT ra.year,
           re.driver_id,
           SUM(re.points) AS total_points
    FROM results re
    JOIN races  ra ON ra.race_id = re.race_id
    GROUP BY ra.year, re.driver_id
),
max_driver_year AS (
    SELECT year,
           MAX(total_points) AS max_driver_points
    FROM driver_year_points
    GROUP BY year
),
constructor_year_points AS (
    SELECT ra.year,
           re.constructor_id,
           SUM(re.points) AS total_points
    FROM results re
    JOIN races  ra ON ra.race_id = re.race_id
    GROUP BY ra.year, re.constructor_id
),
max_constructor_year AS (
    SELECT year,
           MAX(total_points) AS max_constructor_points
    FROM constructor_year_points
    GROUP BY year
),
year_totals AS (
    SELECT d.year,
           d.max_driver_points + c.max_constructor_points AS combined_total
    FROM max_driver_year       d
    JOIN max_constructor_year  c ON c.year = d.year
)
SELECT year
FROM year_totals
ORDER BY combined_total ASC, year ASC
LIMIT 3;