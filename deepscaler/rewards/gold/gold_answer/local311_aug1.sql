-- Task: Find the maximum total points scored by any driver for each constructor in each year (showing up to 100 results).
SELECT sub."year", sub."constructor_id", MAX(sub."driver_points") AS driver_points
FROM (
    SELECT races."year", results."constructor_id", results."driver_id", SUM(results."points") AS driver_points
    FROM "results"
    JOIN "races" ON results."race_id" = races."race_id"
    GROUP BY races."year", results."constructor_id", results."driver_id"
) AS sub
GROUP BY sub."year", sub."constructor_id"
LIMIT 100;