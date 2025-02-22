-- Task: For each year, compute the total points scored by each driver. I want the full name of each driver. Show up to 100 results.
SELECT
    races."year",
    drivers."forename" || ' ' || drivers."surname" AS "driver",
    SUM(results."points") AS "points"
FROM F1.F1.RESULTS results
LEFT JOIN F1.F1.RACES races ON results."race_id" = races."race_id"
LEFT JOIN F1.F1.DRIVERS drivers ON results."driver_id" = drivers."driver_id"
GROUP BY
    races."year",
    drivers."forename",
    drivers."surname"
ORDER BY
    races."year",
    "points" DESC
LIMIT 100;