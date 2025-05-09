WITH DriverPoints AS (
    SELECT ra."year", r."driver_id", ROUND(SUM(r."points"), 4) AS "total_points"
    FROM F1.F1."RESULTS" r
    JOIN F1.F1."RACES" ra ON r."race_id" = ra."race_id"
    GROUP BY ra."year", r."driver_id"
),
DriverRank AS (
    SELECT dp."year", dp."driver_id", dp."total_points",
           RANK() OVER (PARTITION BY dp."year" ORDER BY dp."total_points" DESC NULLS LAST) AS "rank"
    FROM DriverPoints dp
),
TopDriverPerYear AS (
    SELECT dr."year", dr."driver_id", dr."total_points"
    FROM DriverRank dr
    WHERE dr."rank" = 1
),
ConstructorPoints AS (
    SELECT ra."year", r."constructor_id", ROUND(SUM(r."points"), 4) AS "total_points"
    FROM F1.F1."RESULTS" r
    JOIN F1.F1."RACES" ra ON r."race_id" = ra."race_id"
    GROUP BY ra."year", r."constructor_id"
),
ConstructorRank AS (
    SELECT cp."year", cp."constructor_id", cp."total_points",
           RANK() OVER (PARTITION BY cp."year" ORDER BY cp."total_points" DESC NULLS LAST) AS "rank"
    FROM ConstructorPoints cp
),
TopConstructorPerYear AS (
    SELECT cr."year", cr."constructor_id", cr."total_points"
    FROM ConstructorRank cr
    WHERE cr."rank" = 1
)
SELECT tdp."year", d."full_name" AS "Driver_Full_Name", c."name" AS "Constructor_Name"
FROM TopDriverPerYear tdp
JOIN F1.F1."DRIVERS" d ON tdp."driver_id" = d."driver_id"
JOIN TopConstructorPerYear tcp ON tdp."year" = tcp."year"
JOIN F1.F1."CONSTRUCTORS" c ON tcp."constructor_id" = c."constructor_id"
ORDER BY tdp."year" ASC NULLS LAST;