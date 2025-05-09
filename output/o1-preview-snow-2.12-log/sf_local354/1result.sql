WITH driver_races AS (
    SELECT
        r."driver_id",
        d."full_name",
        ra."year",
        ra."round",
        r."constructor_id"
    FROM "F1"."F1"."RESULTS" r
    JOIN "F1"."F1"."RACES" ra ON r."race_id" = ra."race_id"
    JOIN "F1"."F1"."DRIVERS" d ON r."driver_id" = d."driver_id"
    WHERE ra."year" BETWEEN 1950 AND 1959
),
driver_seasons AS (
    SELECT
        dr."driver_id",
        dr."full_name",
        dr."year",
        COUNT(DISTINCT dr."round") AS "race_count",
        MIN(dr."round") AS "first_round",
        MAX(dr."round") AS "last_round",
        COUNT(DISTINCT dr."constructor_id") AS "constructor_count"
    FROM driver_races dr
    GROUP BY dr."driver_id", dr."full_name", dr."year"
),
driver_constructors AS (
    SELECT
        ds."driver_id",
        ds."full_name",
        ds."year",
        ds."race_count",
        fc."constructor_id" AS "first_constructor_id",
        lc."constructor_id" AS "last_constructor_id",
        ds."constructor_count"
    FROM
        driver_seasons ds
        LEFT JOIN driver_races fc
            ON ds."driver_id" = fc."driver_id" AND ds."year" = fc."year" AND ds."first_round" = fc."round"
        LEFT JOIN driver_races lc
            ON ds."driver_id" = lc."driver_id" AND ds."year" = lc."year" AND ds."last_round" = lc."round"
)
SELECT DISTINCT dc."full_name" AS "name"
FROM driver_constructors dc
WHERE
    dc."race_count" >= 2
    AND dc."first_constructor_id" = dc."last_constructor_id"
    AND dc."constructor_count" = 1
ORDER BY dc."full_name";