WITH driver_year_points AS (
    SELECT r.year,
           res.driver_id,
           SUM(res.points) AS total_points
    FROM results  res
    JOIN races    r ON r.race_id = res.race_id
    GROUP BY r.year, res.driver_id
),
driver_max AS (
    SELECT year,
           MAX(total_points) AS max_points
    FROM driver_year_points
    GROUP BY year
),
top_drivers AS (
    SELECT dyp.year,
           dyp.driver_id,
           COALESCE(dext.full_name,
                    dr.forename || ' ' || dr.surname) AS driver_full_name,
           dyp.total_points
    FROM driver_year_points dyp
    JOIN driver_max dm
         ON dm.year = dyp.year
        AND dm.max_points = dyp.total_points
    LEFT JOIN drivers_ext dext ON dext.driver_id = dyp.driver_id
    LEFT JOIN drivers     dr   ON dr.driver_id  = dyp.driver_id
),
constructor_year_points AS (
    SELECT r.year,
           res.constructor_id,
           SUM(res.points) AS total_points
    FROM results  res
    JOIN races    r ON r.race_id = res.race_id
    GROUP BY r.year, res.constructor_id
),
constructor_max AS (
    SELECT year,
           MAX(total_points) AS max_points
    FROM constructor_year_points
    GROUP BY year
),
top_constructors AS (
    SELECT cyp.year,
           cyp.constructor_id,
           c.name  AS constructor_name,
           cyp.total_points
    FROM constructor_year_points cyp
    JOIN constructor_max cm
         ON cm.year = cyp.year
        AND cm.max_points = cyp.total_points
    JOIN constructors c ON c.constructor_id = cyp.constructor_id
)
SELECT td.year,
       td.driver_full_name,
       td.total_points      AS driver_points,
       tc.constructor_name,
       tc.total_points      AS constructor_points
FROM top_drivers       td
JOIN top_constructors  tc  ON tc.year = td.year
ORDER BY td.year;