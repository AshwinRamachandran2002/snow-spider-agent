WITH driver_max AS (
    SELECT
        ra.year,
        MAX(driver_points) AS d_max
    FROM (
        SELECT
            ra.year,
            res.driver_id,
            SUM(res.points) AS driver_points
        FROM results res
        JOIN races  ra ON ra.race_id = res.race_id
        GROUP BY ra.year, res.driver_id
    ) AS driver_year_points
    JOIN races ra ON ra.year = driver_year_points.year
    GROUP BY ra.year
),
constructor_max AS (
    SELECT
        ra.year,
        MAX(constructor_points) AS c_max
    FROM (
        SELECT
            ra.year,
            res.constructor_id,
            SUM(res.points) AS constructor_points
        FROM results res
        JOIN races ra ON ra.race_id = res.race_id
        GROUP BY ra.year, res.constructor_id
    ) AS constructor_year_points
    JOIN races ra ON ra.year = constructor_year_points.year
    GROUP BY ra.year
),
year_totals AS (
    SELECT
        d.year,
        d.d_max + c.c_max AS total_points
    FROM driver_max      d
    JOIN constructor_max c ON d.year = c.year
)
SELECT
    year
FROM year_totals
ORDER BY total_points ASC, year ASC
LIMIT 3;