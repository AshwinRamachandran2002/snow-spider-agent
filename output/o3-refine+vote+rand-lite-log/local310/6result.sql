WITH driver_max AS (
    /* highest season total scored by any single driver */
    SELECT r.year,
           MAX(driver_points) AS max_driver_points
    FROM (
        SELECT ra.year,
               re.driver_id,
               SUM(COALESCE(re.points,0)) AS driver_points
        FROM results re
        JOIN races ra ON ra.race_id = re.race_id
        GROUP BY ra.year, re.driver_id
    ) r
    GROUP BY r.year
),
constructor_max AS (
    /* highest season total scored by any single constructor */
    SELECT r.year,
           MAX(constructor_points) AS max_constructor_points
    FROM (
        SELECT ra.year,
               re.constructor_id,
               SUM(COALESCE(re.points,0)) AS constructor_points
        FROM results re
        JOIN races ra ON ra.race_id = re.race_id
        GROUP BY ra.year, re.constructor_id
    ) r
    GROUP BY r.year
),
year_totals AS (
    /* sum the two maxima for each year */
    SELECT d.year,
           d.max_driver_points + c.max_constructor_points AS combined_total
    FROM driver_max d
    JOIN constructor_max c ON c.year = d.year
)
SELECT year
FROM year_totals
ORDER BY combined_total ASC, year
LIMIT 3;