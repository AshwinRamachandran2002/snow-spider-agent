WITH driver_points AS (
    SELECT
        ra."year"                           AS year,          -- season
        r."driver_id",
        SUM(COALESCE(r."points",0))         AS total_driver_points
    FROM F1.F1."RESULTS"  r
    JOIN F1.F1."RACES"    ra
      ON r."race_id" = ra."race_id"
    GROUP BY ra."year", r."driver_id"
),
max_driver AS (
    SELECT
        year,
        MAX(total_driver_points)            AS max_driver_points
    FROM driver_points
    GROUP BY year
),
constructor_points AS (
    SELECT
        ra."year"                           AS year,
        r."constructor_id",
        SUM(COALESCE(r."points",0))         AS total_constructor_points
    FROM F1.F1."RESULTS"  r
    JOIN F1.F1."RACES"    ra
      ON r."race_id" = ra."race_id"
    GROUP BY ra."year", r."constructor_id"
),
max_constructor AS (
    SELECT
        year,
        MAX(total_constructor_points)       AS max_constructor_points
    FROM constructor_points
    GROUP BY year
),
year_totals AS (
    SELECT
        d.year,
        d.max_driver_points,
        c.max_constructor_points,
        d.max_driver_points + c.max_constructor_points AS total
    FROM max_driver      d
    JOIN max_constructor c
      ON d.year = c.year
)
SELECT
    year,
    total
FROM year_totals
ORDER BY total ASC, year ASC
LIMIT 3;