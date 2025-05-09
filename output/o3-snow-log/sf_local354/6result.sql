/*  1) get every race a driver took part in during the 1950-1959 seasons
    2) for every driver-season keep the first and the last round they entered
       – together with the constructor used in those rounds
    3) keep only seasons where
         • the driver entered at least two different rounds
         • the constructor in the first and last round is the same
    4) return the driver, the season and that constructor
*/
WITH driver_races_50s AS (      -- step-1
    SELECT
        r."year"                     AS "season_year",
        r."round",
        res."driver_id",
        res."constructor_id"
    FROM F1.F1."RESULTS"   res
    JOIN F1.F1."RACES"     r
          ON r."race_id" = res."race_id"
    WHERE r."year" BETWEEN 1950 AND 1959
),
season_stats AS (               -- step-2  & step-3 (part-a)
    SELECT
        "driver_id",
        "season_year",
        MIN("round")  AS "first_round",
        MAX("round")  AS "last_round",
        COUNT(DISTINCT "round") AS "races_entered"
    FROM driver_races_50s
    GROUP BY "driver_id", "season_year"
    HAVING COUNT(DISTINCT "round") >= 2          -- at least two different rounds
),
first_last_constructors AS (    -- step-3 (part-b)
    SELECT
        ss."driver_id",
        ss."season_year",
        dr1."constructor_id"    AS "first_constructor_id",
        dr2."constructor_id"    AS "last_constructor_id"
    FROM season_stats  ss
    JOIN driver_races_50s dr1
          ON dr1."driver_id"   = ss."driver_id"
         AND dr1."season_year" = ss."season_year"
         AND dr1."round"       = ss."first_round"
    JOIN driver_races_50s dr2
          ON dr2."driver_id"   = ss."driver_id"
         AND dr2."season_year" = ss."season_year"
         AND dr2."round"       = ss."last_round"
    WHERE dr1."constructor_id" = dr2."constructor_id"   -- same constructor at first & last race
)
SELECT DISTINCT                 -- step-4
       d."full_name"            AS "driver_name",
       flc."season_year",
       c."name"                 AS "constructor_name"
FROM first_last_constructors flc
JOIN F1.F1."DRIVERS"      d  ON d."driver_id"      = flc."driver_id"
JOIN F1.F1."CONSTRUCTORS" c  ON c."constructor_id" = flc."first_constructor_id"
ORDER BY "driver_name", "season_year";