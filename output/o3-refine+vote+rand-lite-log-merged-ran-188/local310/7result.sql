WITH driver_points AS (
    SELECT ra.year,
           r.driver_id,
           SUM(COALESCE(r.points,0)) AS total_driver_points
    FROM results r
    JOIN races  ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.driver_id
),
max_driver AS (
    SELECT year,
           MAX(total_driver_points) AS max_driver_points
    FROM driver_points
    GROUP BY year
),
constructor_points AS (
    SELECT ra.year,
           r.constructor_id,
           SUM(COALESCE(r.points,0)) AS total_constructor_points
    FROM results r
    JOIN races ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.constructor_id
),
max_constructor AS (
    SELECT year,
           MAX(total_constructor_points) AS max_constructor_points
    FROM constructor_points
    GROUP BY year
),
year_totals AS (
    SELECT d.year,
           d.max_driver_points + c.max_constructor_points AS combined_max_points
    FROM max_driver d
    JOIN max_constructor c USING (year)
)
SELECT year
FROM year_totals
ORDER BY combined_max_points ASC, year ASC
LIMIT 3;