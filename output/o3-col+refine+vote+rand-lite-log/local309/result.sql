WITH driver_year_points AS (
    SELECT r."year",
           ds."driver_id",
           SUM(ds."points") AS "total_points"
    FROM   "driver_standings"  ds
    JOIN   "races"             r  ON r."race_id" = ds."race_id"
    GROUP  BY r."year", ds."driver_id"
),
top_driver AS (
    SELECT dyp."year",
           dyp."driver_id",
           dyp."total_points"
    FROM   driver_year_points dyp
    JOIN  (SELECT "year",
                  MAX("total_points") AS "max_points"
           FROM   driver_year_points
           GROUP  BY "year") mx
      ON  mx."year" = dyp."year"
     AND mx."max_points" = dyp."total_points"
),
constructor_year_points AS (
    SELECT r."year",
           cs."constructor_id",
           SUM(cs."points") AS "total_points"
    FROM   "constructor_standings" cs
    JOIN   "races"                r ON r."race_id" = cs."race_id"
    GROUP  BY r."year", cs."constructor_id"
),
top_constructor AS (
    SELECT cyp."year",
           cyp."constructor_id",
           cyp."total_points"
    FROM   constructor_year_points cyp
    JOIN  (SELECT "year",
                  MAX("total_points") AS "max_points"
           FROM   constructor_year_points
           GROUP  BY "year") mx
      ON  mx."year" = cyp."year"
     AND mx."max_points" = cyp."total_points"
)
SELECT td."year",
       dex."full_name"          AS "champion_driver",
       td."total_points"        AS "driver_points",
       c."name"                 AS "champion_constructor",
       tc."total_points"        AS "constructor_points"
FROM   top_driver      td
JOIN   "drivers_ext"   dex ON dex."driver_id"    = td."driver_id"
JOIN   top_constructor tc  ON tc."year"          = td."year"
JOIN   "constructors"  c   ON c."constructor_id" = tc."constructor_id"
ORDER  BY td."year";