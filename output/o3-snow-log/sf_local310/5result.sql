WITH driver_year_points AS (
    SELECT
        r2."year",
        r1."driver_id",
        SUM(r1."points") AS total_points
    FROM F1.F1.RESULTS r1
    JOIN F1.F1.RACES  r2
      ON r2."race_id" = r1."race_id"
    GROUP BY r2."year", r1."driver_id"
),
driver_year_max AS (
    SELECT
        "year",
        MAX(total_points) AS max_driver_points
    FROM driver_year_points
    GROUP BY "year"
),
constructor_year_points AS (
    SELECT
        r2."year",
        r1."constructor_id",
        SUM(r1."points") AS total_points
    FROM F1.F1.RESULTS r1
    JOIN F1.F1.RACES  r2
      ON r2."race_id" = r1."race_id"
    GROUP BY r2."year", r1."constructor_id"
),
constructor_year_max AS (
    SELECT
        "year",
        MAX(total_points) AS max_constructor_points
    FROM constructor_year_points
    GROUP BY "year"
),
year_totals AS (
    SELECT
        d."year",
        d.max_driver_points + c.max_constructor_points AS total_points
    FROM driver_year_max d
    JOIN constructor_year_max c
      ON d."year" = c."year"
)
SELECT
    "year",
    total_points
FROM year_totals
ORDER BY total_points ASC, "year" ASC
LIMIT 3;