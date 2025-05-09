WITH driver_races AS (
    SELECT r."driver_id",
           ra."year",
           ra."round",
           r."constructor_id"
    FROM "results" r
    JOIN "races"  ra ON ra."race_id" = r."race_id"
    WHERE ra."year" BETWEEN 1950 AND 1959
),
season_summary AS (
    SELECT "driver_id",
           "year",
           MIN("round")  AS first_round,
           MAX("round")  AS last_round,
           COUNT(DISTINCT "round") AS rounds_entered
    FROM driver_races
    GROUP BY "driver_id", "year"
    HAVING rounds_entered >= 2
),
first_last_constructor AS (
    SELECT ss."driver_id",
           ss."year",
           MAX(CASE WHEN dr."round" = ss.first_round THEN dr."constructor_id" END) AS first_constructor,
           MAX(CASE WHEN dr."round" = ss.last_round  THEN dr."constructor_id" END) AS last_constructor
    FROM season_summary ss
    JOIN driver_races dr
      ON dr."driver_id" = ss."driver_id"
     AND dr."year"      = ss."year"
    GROUP BY ss."driver_id", ss."year"
),
qualified AS (
    SELECT "driver_id", "year"
    FROM first_last_constructor
    WHERE first_constructor = last_constructor
)
SELECT DISTINCT
       d."forename" || ' ' || d."surname" AS driver_name,
       q."year"                            AS season
FROM qualified q
JOIN "drivers" d ON d."driver_id" = q."driver_id"
ORDER BY driver_name, season;