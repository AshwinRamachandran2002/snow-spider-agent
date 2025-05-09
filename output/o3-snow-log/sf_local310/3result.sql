WITH RESULTS_WITH_YEAR AS (
    SELECT 
        rce."year",
        res."driver_id",
        res."constructor_id",
        COALESCE(res."points", 0) AS "points"
    FROM F1.F1."RESULTS" res
    JOIN F1.F1."RACES"  rce
      ON res."race_id" = rce."race_id"
), 
DRIVER_YEAR_POINTS AS (
    SELECT 
        "year",
        "driver_id",
        SUM("points") AS "driver_points"
    FROM RESULTS_WITH_YEAR
    GROUP BY "year", "driver_id"
), 
MAX_DRIVER_POINTS_PER_YEAR AS (
    SELECT 
        "year",
        MAX("driver_points") AS "max_driver_points"
    FROM DRIVER_YEAR_POINTS
    GROUP BY "year"
), 
CONSTRUCTOR_YEAR_POINTS AS (
    SELECT 
        "year",
        "constructor_id",
        SUM("points") AS "constructor_points"
    FROM RESULTS_WITH_YEAR
    GROUP BY "year", "constructor_id"
), 
MAX_CONSTRUCTOR_POINTS_PER_YEAR AS (
    SELECT 
        "year",
        MAX("constructor_points") AS "max_constructor_points"
    FROM CONSTRUCTOR_YEAR_POINTS
    GROUP BY "year"
), 
YEAR_TOTALS AS (
    SELECT 
        d."year",
        d."max_driver_points",
        c."max_constructor_points",
        d."max_driver_points" + c."max_constructor_points" AS "combined_max_points"
    FROM MAX_DRIVER_POINTS_PER_YEAR d
    JOIN MAX_CONSTRUCTOR_POINTS_PER_YEAR c
      ON d."year" = c."year"
)
SELECT 
    "year"
FROM YEAR_TOTALS
ORDER BY "combined_max_points" ASC, "year" ASC
LIMIT 3;