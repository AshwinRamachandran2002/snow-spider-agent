WITH driver_year_points AS (
    SELECT ra.year,
           r.driver_id,
           SUM(r.points) AS driver_points
    FROM results AS r
    JOIN races   AS ra ON ra.race_id = r.race_id
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
    FROM results AS r
    JOIN races   AS ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.constructor_id
),
max_constructor_year AS (
    SELECT year,
           MAX(constructor_points) AS max_constructor_points
    FROM constructor_year_points
    GROUP BY year
),
combined AS (
    SELECT d.year,
           d.max_driver_points + c.max_constructor_points AS combined_max
    FROM max_driver_year       AS d
    JOIN max_constructor_year  AS c USING (year)
)
SELECT year,
       combined_max
FROM combined
ORDER BY combined_max ASC, year ASC
LIMIT 3;