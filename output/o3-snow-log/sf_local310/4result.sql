WITH driver_totals AS (   -- total points per driver per year
    SELECT
        r."year",
        res."driver_id",
        SUM(res."points") AS driver_points
    FROM F1.F1."RESULTS"      res
    JOIN F1.F1."RACES"        r   ON r."race_id" = res."race_id"
    GROUP BY r."year", res."driver_id"
),
max_driver_per_year AS (    -- highest-scoring driver each year
    SELECT
        "year",
        MAX(driver_points) AS max_driver_points
    FROM driver_totals
    GROUP BY "year"
),
constructor_totals AS (     -- total points per constructor per year
    SELECT
        r."year",
        res."constructor_id",
        SUM(res."points") AS constructor_points
    FROM F1.F1."RESULTS"      res
    JOIN F1.F1."RACES"        r   ON r."race_id" = res."race_id"
    GROUP BY r."year", res."constructor_id"
),
max_constructor_per_year AS (   -- highest-scoring constructor each year
    SELECT
        "year",
        MAX(constructor_points) AS max_constructor_points
    FROM constructor_totals
    GROUP BY "year"
),
year_sums AS (              -- sum of those two maxima per year
    SELECT
        d."year",
        d.max_driver_points + c.max_constructor_points AS total_max_points
    FROM max_driver_per_year      d
    JOIN max_constructor_per_year c USING ("year")
)
SELECT
    "year"
FROM year_sums
ORDER BY total_max_points ASC NULLS LAST   -- smallest sums first
LIMIT 3;                                    -- three required years