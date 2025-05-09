WITH driver_season_points AS (     -- total points per driver & season
    SELECT
        r."year",
        ds."driver_id",
        SUM(ds."points") AS "points"
    FROM F1.F1.DRIVER_STANDINGS ds
    JOIN F1.F1.RACES r
          ON r."race_id" = ds."race_id"
    GROUP BY r."year", ds."driver_id"
),  
top_driver_per_year AS (           -- keep only the #1 driver each season
    SELECT
        dsp."year",
        dsp."driver_id",
        dsp."points",
        ROW_NUMBER() OVER (PARTITION BY dsp."year" ORDER BY dsp."points" DESC) AS "rn"
    FROM driver_season_points dsp
),  
constructor_season_points AS (     -- total points per constructor & season
    SELECT
        r."year",
        cs."constructor_id",
        SUM(cs."points") AS "points"
    FROM F1.F1.CONSTRUCTOR_STANDINGS cs
    JOIN F1.F1.RACES r
          ON r."race_id" = cs."race_id"
    GROUP BY r."year", cs."constructor_id"
),  
top_constructor_per_year AS (      -- keep only the #1 constructor each season
    SELECT
        csp."year",
        csp."constructor_id",
        csp."points",
        ROW_NUMBER() OVER (PARTITION BY csp."year" ORDER BY csp."points" DESC) AS "rn"
    FROM constructor_season_points csp
)  
SELECT
    td."year",
    d."full_name"    AS "top_driver",
    td."points"      AS "driver_points",
    ce."short_name"  AS "top_constructor",
    tc."points"      AS "constructor_points"
FROM top_driver_per_year td
JOIN F1.F1.DRIVERS            d  ON d."driver_id"       = td."driver_id"
JOIN top_constructor_per_year tc ON tc."year"           = td."year"
JOIN F1.F1.CONSTRUCTORS_EXT   ce ON ce."constructor_id" = tc."constructor_id"
WHERE td."rn" = 1
  AND tc."rn" = 1
ORDER BY td."year";