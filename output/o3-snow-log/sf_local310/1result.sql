WITH race_year AS (
    SELECT 
        "race_id",
        "year"
    FROM F1.F1.RACES
),

driver_max AS (
    /* highest season-total points scored by any driver each year */
    SELECT 
        "year",
        MAX(season_driver_points) AS max_driver_points
    FROM (
        SELECT 
            ry."year",
            r."driver_id",
            SUM(r."points") AS season_driver_points
        FROM F1.F1.RESULTS r
        JOIN race_year ry
              ON ry."race_id" = r."race_id"
        GROUP BY ry."year", r."driver_id"
    ) t
    GROUP BY "year"
),

constructor_max AS (
    /* highest season-total points scored by any constructor each year */
    SELECT 
        "year",
        MAX(season_constructor_points) AS max_constructor_points
    FROM (
        SELECT 
            ry."year",
            r."constructor_id",
            SUM(r."points") AS season_constructor_points
        FROM F1.F1.RESULTS r
        JOIN race_year ry
              ON ry."race_id" = r."race_id"
        GROUP BY ry."year", r."constructor_id"
    ) t
    GROUP BY "year"
),

combined_totals AS (
    /* sum of the two maxima for every year */
    SELECT 
        d."year",
        d.max_driver_points + c.max_constructor_points AS combined_total
    FROM driver_max d
    JOIN constructor_max c
          ON c."year" = d."year"
)

SELECT 
    "year"
FROM combined_totals
ORDER BY combined_total ASC NULLS LAST, "year" ASC
LIMIT 3;