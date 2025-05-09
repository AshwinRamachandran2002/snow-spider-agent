WITH
driver_totals AS (
    SELECT
        "d"."driver_id",
        "d"."full_name",
        "r"."year",
        SUM("res"."points") AS "total_points"
    FROM "results" AS "res"
    JOIN "drivers" AS "d" ON "res"."driver_id" = "d"."driver_id"
    JOIN "races" AS "r" ON "res"."race_id" = "r"."race_id"
    GROUP BY "d"."driver_id", "r"."year"
),
driver_max_points AS (
    SELECT
        "year",
        MAX("total_points") AS "max_points"
    FROM "driver_totals"
    GROUP BY "year"
),
top_drivers AS (
    SELECT
        "dt"."year",
        "dt"."full_name" AS "driver_name"
    FROM "driver_totals" AS "dt"
    JOIN "driver_max_points" AS "dmp"
        ON "dt"."year" = "dmp"."year"
        AND "dt"."total_points" = "dmp"."max_points"
),
constructor_totals AS (
    SELECT
        "c"."constructor_id",
        "c"."name" AS "constructor_name",
        "r"."year",
        SUM("res"."points") AS "total_points"
    FROM "results" AS "res"
    JOIN "constructors" AS "c" ON "res"."constructor_id" = "c"."constructor_id"
    JOIN "races" AS "r" ON "res"."race_id" = "r"."race_id"
    GROUP BY "c"."constructor_id", "r"."year"
),
constructor_max_points AS (
    SELECT
        "year",
        MAX("total_points") AS "max_points"
    FROM "constructor_totals"
    GROUP BY "year"
),
top_constructors AS (
    SELECT
        "ct"."year",
        "ct"."constructor_name"
    FROM "constructor_totals" AS "ct"
    JOIN "constructor_max_points" AS "cmp"
        ON "ct"."year" = "cmp"."year"
        AND "ct"."total_points" = "cmp"."max_points"
)
SELECT
    "td"."year",
    "td"."driver_name",
    "tc"."constructor_name"
FROM "top_drivers" AS "td"
JOIN "top_constructors" AS "tc" ON "td"."year" = "tc"."year"
ORDER BY "td"."year" ASC;