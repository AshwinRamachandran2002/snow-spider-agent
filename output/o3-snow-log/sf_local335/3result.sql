WITH "last_race_per_year" AS (
    SELECT 
        "year",
        MAX("round") AS "last_round"
    FROM F1.F1.RACES
    WHERE "year" >= 2001
    GROUP BY "year"
),  
"last_race_ids" AS (
    SELECT 
        r."year",
        r."race_id"
    FROM F1.F1.RACES r
    JOIN "last_race_per_year" l
      ON r."year" = l."year"
     AND r."round" = l."last_round"
),  
"final_driver_points" AS (
    SELECT 
        ds."driver_id",
        ds."points",
        lr."year"
    FROM F1.F1.DRIVER_STANDINGS ds
    JOIN "last_race_ids" lr
      ON ds."race_id" = lr."race_id"
    WHERE ds."points" > 0                      -- only point-scoring drivers
),  
"min_points_per_year" AS (
    SELECT 
        "year",
        MIN("points") AS "min_points"
    FROM "final_driver_points"
    GROUP BY "year"
),  
"bottom_drivers" AS (
    SELECT 
        fdp."year",
        fdp."driver_id",
        fdp."points"
    FROM "final_driver_points" fdp
    JOIN "min_points_per_year" mp
      ON fdp."year" = mp."year"
     AND fdp."points" = mp."min_points"        -- drivers with season-minimum points
),  
"bottom_drivers_constructors" AS (
    SELECT DISTINCT
        bd."year",
        d."constructor_id"
    FROM "bottom_drivers" bd
    JOIN F1.F1.DRIVES d
      ON bd."year" = d."year"
     AND bd."driver_id" = d."driver_id"        -- constructor(s) each bottom driver raced for
),  
"constructor_counts" AS (
    SELECT 
        "constructor_id",
        COUNT(*) AS "seasons_with_bottom_driver"  -- one row per (season, constructor)
    FROM "bottom_drivers_constructors"
    GROUP BY "constructor_id"
),  
"constructor_names" AS (
    SELECT 
        c."constructor_id",
        COALESCE(ce."short_name", c."name") AS "constructor_name"
    FROM F1.F1.CONSTRUCTORS c
    LEFT JOIN F1.F1.CONSTRUCTORS_EXT ce 
           ON c."constructor_id" = ce."constructor_id"
)
SELECT 
    cn."constructor_name",
    cc."seasons_with_bottom_driver"
FROM "constructor_counts" cc
JOIN "constructor_names" cn
  ON cc."constructor_id" = cn."constructor_id"
ORDER BY 
    cc."seasons_with_bottom_driver" DESC NULLS LAST,
    cn."constructor_name"
LIMIT 5;