WITH driver_totals AS (
    SELECT ra.year,
           res.driver_id,
           SUM(res.points) AS total_points
    FROM results AS res
    JOIN races  AS ra ON ra.race_id = res.race_id
    GROUP BY ra.year, res.driver_id
),
max_driver AS (
    SELECT year,
           MAX(total_points) AS max_driver_points
    FROM driver_totals
    GROUP BY year
),
constructor_totals AS (
    SELECT ra.year,
           res.constructor_id,
           SUM(res.points) AS total_points
    FROM results AS res
    JOIN races  AS ra ON ra.race_id = res.race_id
    GROUP BY ra.year, res.constructor_id
),
max_constructor AS (
    SELECT year,
           MAX(total_points) AS max_constructor_points
    FROM constructor_totals
    GROUP BY year
),
year_sums AS (
    SELECT d.year,
           d.max_driver_points + c.max_constructor_points AS combined_max
    FROM max_driver      AS d
    JOIN max_constructor AS c ON c.year = d.year
)
SELECT year
FROM year_sums
ORDER BY combined_max ASC, year ASC
LIMIT 3;