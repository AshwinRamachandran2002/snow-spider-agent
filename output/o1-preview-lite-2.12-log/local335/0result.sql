WITH
    driver_points AS (
        SELECT
            ra."year",
            r."driver_id",
            SUM(r."points") AS "total_points"
        FROM
            "results" r
            JOIN "races" ra ON r."race_id" = ra."race_id"
        WHERE
            ra."year" >= 2000
        GROUP BY
            ra."year",
            r."driver_id"
    ),
    min_points_per_year AS (
        SELECT
            dp."year",
            MIN(dp."total_points") AS "min_points"
        FROM
            driver_points dp
        GROUP BY
            dp."year"
    ),
    drivers_with_min_points AS (
        SELECT
            dp."year",
            dp."driver_id"
        FROM
            driver_points dp
            JOIN min_points_per_year mp ON dp."year" = mp."year" AND dp."total_points" = mp."min_points"
    ),
    drivers_with_min_points_and_constructors AS (
        SELECT DISTINCT
            dwmp."year",
            dwmp."driver_id",
            r."constructor_id"
        FROM
            drivers_with_min_points dwmp
            JOIN "results" r ON dwmp."driver_id" = r."driver_id"
            JOIN "races" ra ON r."race_id" = ra."race_id"
        WHERE
            ra."year" = dwmp."year"
    )
SELECT
    c."constructor_ref",
    COUNT(DISTINCT dmc."year") AS "Seasons_with_Fewest_Points"
FROM
    drivers_with_min_points_and_constructors dmc
    JOIN "constructors" c ON dmc."constructor_id" = c."constructor_id"
GROUP BY
    c."constructor_ref"
ORDER BY
    "Seasons_with_Fewest_Points" DESC
LIMIT
    5;