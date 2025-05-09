WITH driver_year_points AS (
    SELECT r.year,
           res.driver_id,
           SUM(res.points) AS driver_points
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
    GROUP BY r.year, res.driver_id
),
max_driver_per_year AS (
    SELECT year,
           MAX(driver_points) AS max_driver_points
    FROM driver_year_points
    GROUP BY year
),
constructor_year_points AS (
    SELECT r.year,
           res.constructor_id,
           SUM(res.points) AS constructor_points
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
    GROUP BY r.year, res.constructor_id
),
max_constructor_per_year AS (
    SELECT year,
           MAX(constructor_points) AS max_constructor_points
    FROM constructor_year_points
    GROUP BY year
),
combined_totals AS (
    SELECT d.year,
           d.max_driver_points,
           c.max_constructor_points,
           d.max_driver_points + c.max_constructor_points AS combined_total
    FROM max_driver_per_year      AS d
    JOIN max_constructor_per_year AS c USING (year)
)
SELECT year,
       max_driver_points,
       max_constructor_points,
       combined_total
FROM combined_totals
ORDER BY combined_total ASC, year ASC
LIMIT 3;