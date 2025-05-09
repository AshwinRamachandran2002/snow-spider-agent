WITH DriverTotals AS (
    SELECT ra."year", r."driver_id", ROUND(SUM(r."points"), 4) AS total_points
    FROM "results" r
    JOIN "races" ra ON r."race_id" = ra."race_id"
    GROUP BY ra."year", r."driver_id"
),
MaxDriverPoints AS (
    SELECT "year", MAX(total_points) AS max_points
    FROM DriverTotals
    GROUP BY "year"
),
TopDrivers AS (
    SELECT dt."year", dt."driver_id"
    FROM DriverTotals dt
    JOIN MaxDriverPoints mdp 
      ON dt."year" = mdp."year" AND dt.total_points = mdp.max_points
),
ConstructorTotals AS (
    SELECT ra."year", r."constructor_id", ROUND(SUM(r."points"), 4) AS total_points
    FROM "results" r
    JOIN "races" ra ON r."race_id" = ra."race_id"
    GROUP BY ra."year", r."constructor_id"
),
MaxConstructorPoints AS (
    SELECT "year", MAX(total_points) AS max_points
    FROM ConstructorTotals
    GROUP BY "year"
),
TopConstructors AS (
    SELECT ct."year", ct."constructor_id"
    FROM ConstructorTotals ct
    JOIN MaxConstructorPoints mcp 
      ON ct."year" = mcp."year" AND ct.total_points = mcp.max_points
)
SELECT 
    td."year" AS Year, 
    d."full_name" AS Driver_Name, 
    c."name" AS Constructor_Name
FROM TopDrivers td
JOIN "drivers" d ON td."driver_id" = d."driver_id"
JOIN TopConstructors tc ON td."year" = tc."year"
JOIN "constructors" c ON tc."constructor_id" = c."constructor_id"
ORDER BY td."year";