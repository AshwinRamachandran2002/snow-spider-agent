WITH driver_points AS (
    SELECT r."year", res."driver_id", SUM(res."points") AS total_points
    FROM "results" res
    JOIN "races" r ON res."race_id" = r."race_id"
    GROUP BY r."year", res."driver_id"
),
max_driver_points AS (
    SELECT "year", MAX(total_points) AS max_driver_points
    FROM driver_points
    GROUP BY "year"
),
constructor_points AS (
    SELECT r."year", res."constructor_id", SUM(res."points") AS total_points
    FROM "results" res
    JOIN "races" r ON res."race_id" = r."race_id"
    GROUP BY r."year", res."constructor_id"
),
max_constructor_points AS (
    SELECT "year", MAX(total_points) AS max_constructor_points
    FROM constructor_points
    GROUP BY "year"
),
total_max_points AS (
    SELECT d."year", round(d.max_driver_points + c.max_constructor_points, 4) AS total_points
    FROM max_driver_points d
    JOIN max_constructor_points c ON d."year" = c."year"
)
SELECT "year", total_points
FROM total_max_points
ORDER BY total_points ASC
LIMIT 3;