-- Task: Identify the top 3 constructors with the highest combined points in a single year, where the combined points are calculated as the sum of the constructor's total points and their best driver's total points for that year. For each, provide the constructor name, the year they achieved this, and the combined points.
WITH year_points AS (
    SELECT 
        races."year",
        drivers."forename" || ' ' || drivers."surname" AS "driver",
        constructors."name" AS "constructor",
        SUM(results."points") AS "points"
    FROM F1.F1.RESULTS results
    LEFT JOIN F1.F1.RACES races 
        ON results."race_id" = races."race_id"
    LEFT JOIN F1.F1.DRIVERS drivers 
        ON results."driver_id" = drivers."driver_id"
    LEFT JOIN F1.F1.CONSTRUCTORS constructors 
        ON results."constructor_id" = constructors."constructor_id"
    GROUP BY 
        races."year", 
        drivers."forename", 
        drivers."surname", 
        constructors."name"
    
    UNION
    
    SELECT 
        races."year",
        NULL AS "driver",
        constructors."name" AS "constructor",
        SUM(results."points") AS "points"
    FROM F1.F1.RESULTS results
    LEFT JOIN F1.F1.RACES races 
        ON results."race_id" = races."race_id"
    LEFT JOIN F1.F1.DRIVERS drivers 
        ON results."driver_id" = drivers."driver_id"
    LEFT JOIN F1.F1.CONSTRUCTORS constructors 
        ON results."constructor_id" = constructors."constructor_id"
    GROUP BY 
        races."year", 
        constructors."name"
),
max_points AS (
    SELECT 
        "year",
        "constructor",
        MAX(CASE WHEN "driver" IS NOT NULL THEN "points" ELSE NULL END) AS "max_driver_points",
        MAX(CASE WHEN "constructor" IS NOT NULL THEN "points" ELSE NULL END) AS "max_constructor_points"
    FROM year_points
    GROUP BY 
        "year", 
        "constructor"
)
SELECT 
    constructors_year_points."year",
    max_points."constructor",
    max_points."max_driver_points" + max_points."max_constructor_points" AS "combined_points"
FROM max_points
LEFT JOIN year_points AS drivers_year_points
    ON max_points."year" = drivers_year_points."year"
    AND max_points."max_driver_points" = drivers_year_points."points"
    AND drivers_year_points."driver" IS NOT NULL
LEFT JOIN year_points AS constructors_year_points
    ON max_points."year" = constructors_year_points."year"
    AND max_points."max_constructor_points" = constructors_year_points."points"
    AND constructors_year_points."constructor" IS NOT NULL
ORDER BY 
    "combined_points" DESC
LIMIT 3;