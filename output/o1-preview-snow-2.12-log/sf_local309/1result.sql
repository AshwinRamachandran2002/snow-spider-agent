WITH driver_totals AS (
    SELECT
        R."year",
        D."driver_id",
        D."full_name",
        SUM(RES."points") AS "total_points"
    FROM
        "F1"."F1"."RESULTS" RES
        JOIN "F1"."F1"."RACES" R ON RES."race_id" = R."race_id"
        JOIN "F1"."F1"."DRIVERS" D ON RES."driver_id" = D."driver_id"
    GROUP BY
        R."year",
        D."driver_id",
        D."full_name"
),
driver_points AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "year" ORDER BY "total_points" DESC NULLS LAST) AS rn
    FROM
        driver_totals
),
top_driver AS (
    SELECT
        "year",
        "full_name" AS "driver_full_name"
    FROM
        driver_points
    WHERE rn = 1
),
constructor_totals AS (
    SELECT
        R."year",
        C."constructor_id",
        C."name" AS "constructor_name",
        SUM(RES."points") AS "total_points"
    FROM
        "F1"."F1"."RESULTS" RES
        JOIN "F1"."F1"."RACES" R ON RES."race_id" = R."race_id"
        JOIN "F1"."F1"."CONSTRUCTORS" C ON RES."constructor_id" = C."constructor_id"
    GROUP BY
        R."year",
        C."constructor_id",
        C."name"
),
constructor_points AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "year" ORDER BY "total_points" DESC NULLS LAST) AS rn
    FROM
        constructor_totals
),
top_constructor AS (
    SELECT
        "year",
        "constructor_name"
    FROM
        constructor_points
    WHERE rn = 1
)
SELECT
    top_driver."year",
    top_driver."driver_full_name",
    top_constructor."constructor_name"
FROM
    top_driver
    JOIN top_constructor ON top_driver."year" = top_constructor."year"
ORDER BY
    top_driver."year";