-- Task: For each year, find the driver who scored the highest total points in that year and the constructor that scored the highest total points in that year. Display the year, the full name of the driver (forename and surname concatenated), and the name of the constructor.

WITH year_points AS (
    SELECT races.year,
           drivers.forename || ' ' || drivers.surname AS driver,
           constructors.name AS constructor,
           SUM(results.points) AS points
    FROM results
    LEFT JOIN races ON results.race_id = races.race_id  -- Ensure these columns exist in your schema
    LEFT JOIN drivers ON results.driver_id = drivers.driver_id  -- Ensure these columns exist in your schema
    LEFT JOIN constructors ON results.constructor_id = constructors.constructor_id  -- Ensure these columns exist in your schema
    GROUP BY races.year, driver
    UNION
    SELECT races.year,
           NULL AS driver,
           constructors.name AS constructor,
           SUM(results.points) AS points
    FROM results
    LEFT JOIN races ON results.race_id = races.race_id  -- Ensure these columns exist in your schema
    LEFT JOIN drivers ON results.driver_id = drivers.driver_id  -- Ensure these columns exist in your schema
    LEFT JOIN constructors ON results.constructor_id = constructors.constructor_id  -- Ensure these columns exist in your schema
    GROUP BY races.year, constructor
),
max_points AS (
    SELECT year,
           MAX(CASE WHEN driver IS NOT NULL THEN points ELSE NULL END) AS max_driver_points,
           MAX(CASE WHEN constructor IS NOT NULL THEN points ELSE NULL END) AS max_constructor_points
    FROM year_points
    GROUP BY year
)
SELECT max_points.year,
       drivers_year_points.driver,
       constructors_year_points.constructor
FROM max_points
LEFT JOIN year_points AS drivers_year_points ON
    max_points.year = drivers_year_points.year AND
    max_points.max_driver_points = drivers_year_points.points AND
    drivers_year_points.driver IS NOT NULL
LEFT JOIN year_points AS constructors_year_points ON
    max_points.year = constructors_year_points.year AND
    max_points.max_constructor_points = constructors_year_points.points AND
    constructors_year_points.constructor IS NOT NULL
ORDER BY max_points.year;