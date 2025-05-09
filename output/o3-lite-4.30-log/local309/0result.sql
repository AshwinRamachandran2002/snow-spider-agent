WITH final_races AS (
    SELECT r."year",
           r."race_id"
    FROM   "races" r
    WHERE  r."round" = (
              SELECT MAX(r2."round")
              FROM   "races" r2
              WHERE  r2."year" = r."year"
           )
),
driver_rank AS (
    SELECT fr."year",
           ds."driver_id",
           ds."points",
           ROW_NUMBER() OVER (PARTITION BY fr."year"
                              ORDER BY ds."points" DESC, ds."driver_id") AS rn
    FROM   final_races fr
    JOIN   "driver_standings" ds ON ds."race_id" = fr."race_id"
),
best_driver AS (
    SELECT "year", "driver_id"
    FROM   driver_rank
    WHERE  rn = 1
),
constructor_rank AS (
    SELECT fr."year",
           cs."constructor_id",
           cs."points",
           ROW_NUMBER() OVER (PARTITION BY fr."year"
                              ORDER BY cs."points" DESC, cs."constructor_id") AS rn
    FROM   final_races fr
    JOIN   "constructor_standings" cs ON cs."race_id" = fr."race_id"
),
best_constructor AS (
    SELECT "year", "constructor_id"
    FROM   constructor_rank
    WHERE  rn = 1
)
SELECT bd."year",
       d."forename" || ' ' || d."surname" AS driver_name,
       c."name"                           AS constructor_name
FROM   best_driver      bd
JOIN   "drivers"        d  ON d."driver_id"      = bd."driver_id"
LEFT  JOIN best_constructor bc ON bc."year"      = bd."year"
LEFT  JOIN "constructors"   c  ON c."constructor_id" = bc."constructor_id"
ORDER BY bd."year";