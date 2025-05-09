WITH driver_totals AS (
    SELECT ra.year,
           r.driver_id,
           SUM(r.points) AS driver_points
    FROM results r
    JOIN races  ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.driver_id
),
max_driver AS (
    SELECT year,
           MAX(driver_points) AS max_driver_points
    FROM driver_totals
    GROUP BY year
),
constructor_totals AS (
    SELECT ra.year,
           r.constructor_id,
           SUM(r.points) AS constructor_points
    FROM results r
    JOIN races  ra ON ra.race_id = r.race_id
    GROUP BY ra.year, r.constructor_id
),
max_constructor AS (
    SELECT year,
           MAX(constructor_points) AS max_constructor_points
    FROM constructor_totals
    GROUP BY year
)
SELECT md.year,
       md.max_driver_points + mc.max_constructor_points AS combined_max
FROM max_driver      AS md
JOIN max_constructor AS mc ON mc.year = md.year
ORDER BY combined_max ASC, md.year ASC
LIMIT 3;