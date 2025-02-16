-- Task: For each constructor in each year, find the maximum driver points and maximum constructor points.
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
    LEFT JOIN F1.F1.CONSTRUCTORS constructors 
        ON results."constructor_id" = constructors."constructor_id"
    GROUP BY 
        races."year", 
        constructors."name"
)
SELECT 
    "year",
    "constructor",
    MAX(CASE WHEN "driver" IS NOT NULL THEN "points" ELSE NULL END) AS "max_driver_points",
    MAX(CASE WHEN "driver" IS NULL THEN "points" ELSE NULL END) AS "max_constructor_points"
FROM year_points
GROUP BY 
    "year", 
    "constructor"
LIMIT 100;