WITH driver_totals AS (
    SELECT ra.year,
           re.driver_id,
           SUM(re.points) AS driver_points
    FROM results AS re
    JOIN races  AS ra ON ra.race_id = re.race_id
    GROUP BY ra.year, re.driver_id
),
max_driver AS (
    SELECT year,
           MAX(driver_points) AS max_driver_points
    FROM driver_totals
    GROUP BY year
),
constructor_totals AS (
    SELECT ra.year,
           re.constructor_id,
           SUM(re.points) AS constructor_points
    FROM results AS re
    JOIN races  AS ra ON ra.race_id = re.race_id
    GROUP BY ra.year, re.constructor_id
),
max_constructor AS (
    SELECT year,
           MAX(constructor_points) AS max_constructor_points
    FROM constructor_totals
    GROUP BY year
),
year_totals AS (
    SELECT d.year,
           d.max_driver_points + c.max_constructor_points AS total_points
    FROM max_driver       AS d
    JOIN max_constructor  AS c USING (year)
)
SELECT year
FROM year_totals
ORDER BY total_points ASC, year ASC
LIMIT 3;