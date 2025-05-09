WITH driver_year_points AS (
    SELECT r."year",
           ds."driver_id",
           SUM(ds."points") AS driver_points
    FROM "driver_standings" AS ds
    JOIN "races"           AS r ON r."race_id" = ds."race_id"
    GROUP BY r."year", ds."driver_id"
),
top_driver_per_year AS (
    SELECT dyp.*
    FROM   driver_year_points AS dyp
    JOIN  (
            SELECT "year",
                   MAX(driver_points) AS max_driver_points
            FROM   driver_year_points
            GROUP  BY "year"
          ) AS mx
      ON mx."year"             = dyp."year"
     AND mx.max_driver_points  = dyp.driver_points
),
constructor_year_points AS (
    SELECT r."year",
           cs."constructor_id",
           SUM(cs."points") AS constructor_points
    FROM "constructor_standings" AS cs
    JOIN "races"                AS r ON r."race_id" = cs."race_id"
    GROUP BY r."year", cs."constructor_id"
),
top_constructor_per_year AS (
    SELECT cyp.*
    FROM   constructor_year_points AS cyp
    JOIN  (
            SELECT "year",
                   MAX(constructor_points) AS max_constructor_points
            FROM   constructor_year_points
            GROUP  BY "year"
          ) AS mx
      ON mx."year"                  = cyp."year"
     AND mx.max_constructor_points  = cyp.constructor_points
)
SELECT td."year",
       d."full_name"        AS driver,
       td.driver_points,
       c."name"             AS constructor,
       tc.constructor_points
FROM   top_driver_per_year      AS td
JOIN   "drivers_ext"            AS d  ON d."driver_id"       = td."driver_id"
JOIN   top_constructor_per_year AS tc ON tc."year"           = td."year"
JOIN   "constructors_ext"       AS c  ON c."constructor_id"  = tc."constructor_id"
ORDER  BY td."year";