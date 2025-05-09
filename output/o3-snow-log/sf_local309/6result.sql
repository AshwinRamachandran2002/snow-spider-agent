/*  For every season, return the top-scoring driver (with full name) and the top-scoring constructor. */
WITH DRIVER_TOTALS AS (   -- total points per driver & year
    SELECT   r."year",
             ds."driver_id",
             SUM(ds."points") AS "driver_points"
    FROM     F1.F1."DRIVER_STANDINGS" ds
    JOIN     F1.F1."RACES_EXT"        r  ON ds."race_id" = r."race_id"
    GROUP BY r."year", ds."driver_id"
),
BEST_DRIVERS AS (         -- one (highest) driver per year
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY "year"
                              ORDER BY "driver_points" DESC NULLS LAST) AS "rn"
    FROM   DRIVER_TOTALS
),
CONSTRUCTOR_TOTALS AS (   -- total points per constructor & year
    SELECT   r."year",
             cs."constructor_id",
             SUM(cs."points") AS "constructor_points"
    FROM     F1.F1."CONSTRUCTOR_STANDINGS" cs
    JOIN     F1.F1."RACES_EXT"            r  ON cs."race_id" = r."race_id"
    GROUP BY r."year", cs."constructor_id"
),
BEST_CONSTRUCTORS AS (    -- one (highest) constructor per year
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY "year"
                              ORDER BY "constructor_points" DESC NULLS LAST) AS "rn"
    FROM   CONSTRUCTOR_TOTALS
)

SELECT  bd."year",
        drv."full_name"               AS "driver",
        bd."driver_points",
        con."name"                    AS "constructor",
        bc."constructor_points"
FROM    BEST_DRIVERS      bd
JOIN    F1.F1."DRIVERS"   drv  ON bd."driver_id"      = drv."driver_id"
JOIN    BEST_CONSTRUCTORS bc   ON bd."year"           = bc."year"       AND bc."rn" = 1
JOIN    F1.F1."CONSTRUCTORS" con ON bc."constructor_id" = con."constructor_id"
WHERE   bd."rn" = 1
ORDER BY bd."year";