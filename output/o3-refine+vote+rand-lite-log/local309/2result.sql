WITH driver_year_points AS (
    SELECT 
        races.year,
        results.driver_id,
        SUM(results.points) AS points
    FROM results
    JOIN races ON races.race_id = results.race_id
    GROUP BY races.year, results.driver_id
),
top_driver AS (
    SELECT
        year,
        driver_id,
        points,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY points DESC
        ) AS rn
    FROM driver_year_points
),
constructor_year_points AS (
    SELECT
        races.year,
        results.constructor_id,
        SUM(results.points) AS points
    FROM results
    JOIN races ON races.race_id = results.race_id
    GROUP BY races.year, results.constructor_id
),
top_constructor AS (
    SELECT
        year,
        constructor_id,
        points,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY points DESC
        ) AS rn
    FROM constructor_year_points
)
SELECT
    td.year,
    (drivers.forename || ' ' || drivers.surname)  AS driver_full_name,
    td.points                                     AS driver_points,
    constructors.name                             AS constructor_name,
    tc.points                                     AS constructor_points
FROM top_driver        td
JOIN drivers           ON drivers.driver_id      = td.driver_id
JOIN top_constructor   tc ON tc.year             = td.year   AND tc.rn = 1
JOIN constructors      ON constructors.constructor_id = tc.constructor_id
WHERE td.rn = 1
ORDER BY td.year;