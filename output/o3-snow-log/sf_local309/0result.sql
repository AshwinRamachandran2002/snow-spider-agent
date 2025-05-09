/*  Top-scoring driver and constructor for every Formula 1 season  */
WITH driver_totals AS (
    SELECT
        r."year",
        d."full_name",
        SUM(ds."points")                                   AS "driver_points",
        RANK() OVER (PARTITION BY r."year"
                     ORDER BY SUM(ds."points") DESC)       AS "drv_rank"
    FROM F1.F1."DRIVER_STANDINGS"  ds
    JOIN F1.F1."RACES"             r  ON ds."race_id"   = r."race_id"
    JOIN F1.F1."DRIVERS"           d  ON ds."driver_id" = d."driver_id"
    GROUP BY r."year", d."full_name"
),
top_drivers AS (
    SELECT
        "year",
        "full_name",
        "driver_points"
    FROM driver_totals
    WHERE "drv_rank" = 1          -- keeps all ties, if any
),

constructor_totals AS (
    SELECT
        r."year",
        c."name"                                        AS "constructor_name",
        SUM(cs."points")                                AS "constructor_points",
        RANK() OVER (PARTITION BY r."year"
                     ORDER BY SUM(cs."points") DESC)    AS "con_rank"
    FROM F1.F1."CONSTRUCTOR_STANDINGS"  cs
    JOIN F1.F1."RACES"                  r ON cs."race_id"      = r."race_id"
    JOIN F1.F1."CONSTRUCTORS"           c ON cs."constructor_id"= c."constructor_id"
    GROUP BY r."year", c."name"
),
top_constructors AS (
    SELECT
        "year",
        "constructor_name",
        "constructor_points"
    FROM constructor_totals
    WHERE "con_rank" = 1            -- keeps all ties, if any
)

/* Final result: one row per season */
SELECT
    td."year",
    td."full_name"        AS "top_driver_full_name",
    td."driver_points",
    tc."constructor_name" AS "top_constructor",
    tc."constructor_points"
FROM top_drivers      td
JOIN top_constructors tc ON td."year" = tc."year"
ORDER BY td."year" ASC;