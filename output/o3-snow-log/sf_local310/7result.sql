WITH results_with_year AS (      -- attach season (year) to every result
    SELECT
        rc."year"              AS year,           -- season
        r."driver_id"          AS driver_id,
        r."constructor_id"     AS constructor_id,
        r."points"             AS points
    FROM F1.F1."RESULTS" r
    JOIN F1.F1."RACES"  rc
      ON rc."race_id" = r."race_id"
),

driver_year_totals AS (          -- total points per driver per year
    SELECT
        year,
        driver_id,
        SUM(points) AS driver_points
    FROM results_with_year
    GROUP BY year, driver_id
),

max_driver_per_year AS (         -- best-scoring driver each year
    SELECT
        year,
        MAX(driver_points) AS max_driver_points
    FROM driver_year_totals
    GROUP BY year
),

constructor_year_totals AS (     -- total points per constructor per year
    SELECT
        year,
        constructor_id,
        SUM(points) AS constructor_points
    FROM results_with_year
    GROUP BY year, constructor_id
),

max_constructor_per_year AS (    -- best-scoring constructor each year
    SELECT
        year,
        MAX(constructor_points) AS max_constructor_points
    FROM constructor_year_totals
    GROUP BY year
),

combined AS (                    -- sum of both maxima per year
    SELECT
        d.year,
        d.max_driver_points + c.max_constructor_points AS total_points
    FROM max_driver_per_year      d
    JOIN max_constructor_per_year c
      ON d.year = c.year
)

SELECT
    year,
    total_points
FROM combined
ORDER BY total_points ASC NULLS LAST, year ASC
LIMIT 3;