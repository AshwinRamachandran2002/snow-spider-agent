WITH last_races AS (
    SELECT r."year", r."race_id"
    FROM "races" r
    WHERE r."round" = (
        SELECT MAX(r2."round") FROM "races" r2 WHERE r2."year" = r."year"
    )
),
driver_max_points AS (
    SELECT lr."year", MAX(ds."points") AS "max_driver_points"
    FROM last_races lr
    JOIN "driver_standings" ds ON lr."race_id" = ds."race_id"
    GROUP BY lr."year"
),
constructor_max_points AS (
    SELECT lr."year", MAX(cs."points") AS "max_constructor_points"
    FROM last_races lr
    JOIN "constructor_standings" cs ON lr."race_id" = cs."race_id"
    GROUP BY lr."year"
)
SELECT dmp."year" AS "Year",
       (dmp."max_driver_points" + cmp."max_constructor_points") AS "Sum_of_Highest_Points"
FROM driver_max_points dmp
JOIN constructor_max_points cmp ON dmp."year" = cmp."year"
ORDER BY "Sum_of_Highest_Points" ASC
LIMIT 3;