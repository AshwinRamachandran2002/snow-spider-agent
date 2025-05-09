WITH yearly_driver_points AS (
    SELECT
        ra."year"                               AS season_year,
        r."driver_id"                           AS driver_id,
        SUM(r."points")                         AS driver_points
    FROM F1.F1.RESULTS r
    JOIN F1.F1.RACES  ra
          ON r."race_id" = ra."race_id"
    GROUP BY
        ra."year",
        r."driver_id"
),
max_driver_per_year AS (
    SELECT
        season_year,
        MAX(driver_points)                      AS max_driver_points
    FROM yearly_driver_points
    GROUP BY season_year
),
yearly_constructor_points AS (
    SELECT
        ra."year"                               AS season_year,
        r."constructor_id"                      AS constructor_id,
        SUM(r."points")                         AS constructor_points
    FROM F1.F1.RESULTS r
    JOIN F1.F1.RACES  ra
          ON r."race_id" = ra."race_id"
    GROUP BY
        ra."year",
        r."constructor_id"
),
max_constructor_per_year AS (
    SELECT
        season_year,
        MAX(constructor_points)                 AS max_constructor_points
    FROM yearly_constructor_points
    GROUP BY season_year
),
combined_top_points AS (
    SELECT
        d.season_year                           AS year,
        d.max_driver_points,
        c.max_constructor_points,
        d.max_driver_points + c.max_constructor_points AS combined_points
    FROM max_driver_per_year      d
    JOIN max_constructor_per_year c
          ON d.season_year = c.season_year
)
SELECT
    year
FROM combined_top_points
ORDER BY
    combined_points ASC NULLS LAST,
    year ASC
LIMIT 3;