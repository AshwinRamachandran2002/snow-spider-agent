SELECT DISTINCT "DRIVERS"."full_name" AS "Driver_Name"
FROM (
    -- Drivers who started and ended the season with the same constructor
    SELECT "driver_id", "year"
    FROM (
        SELECT "driver_id", "year",
            MAX(CASE WHEN "is_first_drive_of_season" = 1 THEN "constructor_id" END) AS "first_constructor_id",
            MAX(CASE WHEN "is_final_drive_of_season" = 1 THEN "constructor_id" END) AS "last_constructor_id"
        FROM "F1"."F1"."DRIVES"
        WHERE "year" BETWEEN 1950 AND 1959
        GROUP BY "driver_id", "year"
    ) AS "drives_same_constructor"
    WHERE "first_constructor_id" = "last_constructor_id"
) AS "drivers_same_constructor"
INNER JOIN (
    -- Drivers who participated in at least two different race rounds within the season
    SELECT "driver_id", "year"
    FROM (
        SELECT "driver_id", "RACES"."year", COUNT(DISTINCT "RACES"."round") AS "race_count"
        FROM "F1"."F1"."RESULTS"
        JOIN "F1"."F1"."RACES" ON "RESULTS"."race_id" = "RACES"."race_id"
        WHERE "RACES"."year" BETWEEN 1950 AND 1959
        GROUP BY "driver_id", "RACES"."year"
        HAVING COUNT(DISTINCT "RACES"."round") >= 2
    ) AS "driver_race_counts"
) AS "drivers_with_multiple_races"
ON "drivers_same_constructor"."driver_id" = "drivers_with_multiple_races"."driver_id"
AND "drivers_same_constructor"."year" = "drivers_with_multiple_races"."year"
INNER JOIN "F1"."F1"."DRIVERS"
ON "drivers_same_constructor"."driver_id" = "DRIVERS"."driver_id"
ORDER BY "Driver_Name";