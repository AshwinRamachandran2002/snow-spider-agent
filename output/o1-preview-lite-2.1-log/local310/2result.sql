WITH driver_max AS (
    SELECT r."year", MAX(ds."points") AS "max_driver_points"
    FROM "driver_standings" ds
    JOIN "races" r ON ds."race_id" = r."race_id"
    GROUP BY r."year"
), constructor_max AS (
    SELECT r."year", MAX(cs."points") AS "max_constructor_points"
    FROM "constructor_standings" cs
    JOIN "races" r ON cs."race_id" = r."race_id"
    GROUP BY r."year"
)
SELECT dm."year" AS "Year",
       dm."max_driver_points" + cm."max_constructor_points" AS "Sum_of_Highest_Points"
FROM driver_max dm
JOIN constructor_max cm ON dm."year" = cm."year"
ORDER BY "Sum_of_Highest_Points" ASC
LIMIT 3;