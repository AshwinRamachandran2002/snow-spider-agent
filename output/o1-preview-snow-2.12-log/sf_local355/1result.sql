WITH year_races AS (
    SELECT "year", COUNT(*) AS "total_races"
    FROM "F1"."F1"."RACES"
    GROUP BY "year"
),
driver_races AS (
    SELECT "driver_id", "RACES"."year", COUNT(*) AS "races_participated"
    FROM "F1"."F1"."RESULTS"
    JOIN "F1"."F1"."RACES" ON "RESULTS"."race_id" = "RACES"."race_id"
    GROUP BY "driver_id", "RACES"."year"
),
driver_missed_races AS (
    SELECT 
        dr."driver_id", 
        dr."year", 
        yr."total_races", 
        dr."races_participated",
        (yr."total_races" - dr."races_participated") AS "races_missed"
    FROM driver_races dr
    JOIN year_races yr ON dr."year" = yr."year"
),
drivers_missing_few AS (
    SELECT *
    FROM driver_missed_races
    WHERE "races_missed" < 3
),
missed_rounds AS (
    SELECT 
        dr."driver_id", 
        r."year", 
        r."round"
    FROM drivers_missing_few dr
    JOIN "F1"."F1"."RACES" r ON dr."year" = r."year"
    LEFT JOIN "F1"."F1"."RESULTS" res ON res."race_id" = r."race_id" AND res."driver_id" = dr."driver_id"
    WHERE res."driver_id" IS NULL
),
driver_missed_info AS (
    SELECT 
        mr."driver_id", 
        mr."year", 
        MIN(mr."round") AS "first_missed_round", 
        MAX(mr."round") AS "last_missed_round"
    FROM missed_rounds mr
    GROUP BY mr."driver_id", mr."year"
),
constructors_before AS (
    SELECT 
        d."driver_id", 
        d."year", 
        d."constructor_id"
    FROM "F1"."F1"."DRIVES" d
    JOIN driver_missed_info mi ON d."driver_id" = mi."driver_id" AND d."year" = mi."year"
    WHERE d."last_round" < mi."first_missed_round"
),
constructors_after AS (
    SELECT 
        d."driver_id", 
        d."year", 
        d."constructor_id"
    FROM "F1"."F1"."DRIVES" d
    JOIN driver_missed_info mi ON d."driver_id" = mi."driver_id" AND d."year" = mi."year"
    WHERE d."first_round" > mi."last_missed_round"
),
drivers_switched_teams AS (
    SELECT DISTINCT
        mi."driver_id",
        mi."year",
        mi."first_missed_round",
        mi."last_missed_round"
    FROM driver_missed_info mi
    JOIN constructors_before cb ON mi."driver_id" = cb."driver_id" AND mi."year" = cb."year"
    JOIN constructors_after ca ON mi."driver_id" = ca."driver_id" AND mi."year" = ca."year"
    WHERE cb."constructor_id" <> ca."constructor_id"
)
SELECT 
    "year", 
    ROUND(AVG("first_missed_round"), 4) AS "Average_First_Missed_Round", 
    ROUND(AVG("last_missed_round"), 4) AS "Average_Last_Missed_Round"
FROM drivers_switched_teams
GROUP BY "year"
ORDER BY "year";