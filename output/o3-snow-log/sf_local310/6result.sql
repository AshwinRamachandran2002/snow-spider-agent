WITH results_with_year AS (
    SELECT 
        ra."year",
        re."driver_id",
        re."constructor_id",
        re."points"
    FROM F1.F1."RESULTS"        re
    JOIN F1.F1."RACES"          ra
      ON ra."race_id" = re."race_id"
    WHERE re."points" IS NOT NULL
),
driver_year_points AS (
    SELECT 
        "year",
        "driver_id",
        SUM("points") AS driver_points
    FROM results_with_year
    GROUP BY "year", "driver_id"
),
max_driver AS (
    SELECT 
        "year",
        MAX(driver_points) AS max_driver_points
    FROM driver_year_points
    GROUP BY "year"
),
constructor_year_points AS (
    SELECT 
        "year",
        "constructor_id",
        SUM("points") AS constructor_points
    FROM results_with_year
    GROUP BY "year", "constructor_id"
),
max_constructor AS (
    SELECT 
        "year",
        MAX(constructor_points) AS max_constructor_points
    FROM constructor_year_points
    GROUP BY "year"
),
year_totals AS (
    SELECT 
        d."year",
        d.max_driver_points,
        c.max_constructor_points,
        d.max_driver_points + c.max_constructor_points AS total_points
    FROM max_driver      d
    JOIN max_constructor c
      ON d."year" = c."year"
)
SELECT 
    "year"
FROM year_totals
ORDER BY total_points ASC, "year" ASC
LIMIT 3;