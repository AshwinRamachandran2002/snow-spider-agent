/* drivers whose first and last race of a 1950-59 season were with the
   same constructor and who raced in at least two different rounds
*/
WITH driver_year_rounds AS (          -- every round a driver entered in the 50s
    SELECT
        r."driver_id",
        ra."year",
        ra."round",
        r."constructor_id"
    FROM F1.F1.RESULTS          r
    JOIN F1.F1.RACES            ra ON ra."race_id" = r."race_id"
    WHERE ra."year" BETWEEN 1950 AND 1959
),
driver_year_stats AS (                -- first/last round and # rounds per season
    SELECT
        "driver_id",
        "year",
        MIN("round")  AS first_round,
        MAX("round")  AS last_round,
        COUNT(DISTINCT "round") AS num_rounds
    FROM driver_year_rounds
    GROUP BY "driver_id", "year"
),
first_constructor AS (                -- constructor in the driver’s first round
    SELECT
        s."driver_id",
        s."year",
        drr."constructor_id" AS first_constructor_id
    FROM driver_year_stats  s
    JOIN driver_year_rounds drr
      ON drr."driver_id" = s."driver_id"
     AND drr."year"       = s."year"
     AND drr."round"      = s.first_round
),
last_constructor AS (                 -- constructor in the driver’s last round
    SELECT
        s."driver_id",
        s."year",
        drr."constructor_id" AS last_constructor_id
    FROM driver_year_stats  s
    JOIN driver_year_rounds drr
      ON drr."driver_id" = s."driver_id"
     AND drr."year"       = s."year"
     AND drr."round"      = s.last_round
),
eligible AS (                         -- seasons that satisfy all conditions
    SELECT
        s."driver_id",
        s."year"
    FROM driver_year_stats  s
    JOIN first_constructor  f USING ("driver_id","year")
    JOIN last_constructor   l USING ("driver_id","year")
    WHERE s.num_rounds >= 2
      AND f.first_constructor_id = l.last_constructor_id
)
SELECT DISTINCT
       d."full_name" AS "Driver"
FROM   eligible e
JOIN   F1.F1.DRIVERS d ON d."driver_id" = e."driver_id"
ORDER BY "Driver";