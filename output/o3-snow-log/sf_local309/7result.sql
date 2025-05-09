/*  For every Formula-1 season pick the driver(s) and constructor(s) that
    collected the most championship points.  Ties are kept and their
    names are concatenated with “, ”.                                           */

WITH "DRIVER_SEASON_POINTS" AS (          -- total points each driver scored in a season
    SELECT  r."year",
            ds."driver_id",
            SUM(ds."points") AS "driver_points"
    FROM    F1.F1."DRIVER_STANDINGS"  ds
    JOIN    F1.F1."RACES"             r   ON r."race_id" = ds."race_id"
    GROUP BY r."year", ds."driver_id"
),
"TOP_DRIVERS" AS (                        -- season-leading driver(s)
    SELECT  dsp."year",
            LISTAGG(d."full_name", ', ')
              WITHIN GROUP (ORDER BY d."full_name")   AS "driver_full_name"
    FROM   (
            SELECT dsp.*,
                   MAX(dsp."driver_points") OVER (PARTITION BY dsp."year") AS "max_pts"
            FROM   "DRIVER_SEASON_POINTS" dsp
           ) dsp
    JOIN    F1.F1."DRIVERS" d
           ON d."driver_id" = dsp."driver_id"
    WHERE   dsp."driver_points" = dsp."max_pts"
    GROUP BY dsp."year"
),
"CONSTRUCTOR_SEASON_POINTS" AS (          -- total points each constructor scored in a season
    SELECT  r."year",
            cs."constructor_id",
            SUM(cs."points") AS "constructor_points"
    FROM    F1.F1."CONSTRUCTOR_STANDINGS" cs
    JOIN    F1.F1."RACES"                r  ON r."race_id" = cs."race_id"
    GROUP BY r."year", cs."constructor_id"
),
"TOP_CONSTRUCTORS" AS (                   -- season-leading constructor(s)
    SELECT  csp."year",
            LISTAGG(c."name", ', ')
              WITHIN GROUP (ORDER BY c."name")        AS "constructor_name"
    FROM   (
            SELECT csp.*,
                   MAX(csp."constructor_points") OVER (PARTITION BY csp."year") AS "max_pts"
            FROM   "CONSTRUCTOR_SEASON_POINTS" csp
           ) csp
    JOIN    F1.F1."CONSTRUCTORS" c
           ON c."constructor_id" = csp."constructor_id"
    WHERE   csp."constructor_points" = csp."max_pts"
    GROUP BY csp."year"
)
SELECT  td."year",
        td."driver_full_name"     AS "top_driver_full_name",
        tc."constructor_name"     AS "top_constructor_name"
FROM    "TOP_DRIVERS"      td
JOIN    "TOP_CONSTRUCTORS" tc  ON tc."year" = td."year"
ORDER BY td."year";