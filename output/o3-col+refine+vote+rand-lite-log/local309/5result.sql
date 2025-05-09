WITH driver_totals AS (
  SELECT r."year",
         ds."driver_id",
         SUM(ds."points") AS "driver_points"
  FROM "driver_standings" ds
  JOIN "races"           r  ON r."race_id" = ds."race_id"
  GROUP BY r."year", ds."driver_id"
),
top_drivers AS (
  SELECT dt."year",
         d."forename" || ' ' || d."surname" AS "driver_full_name",
         dt."driver_points",
         ROW_NUMBER() OVER (PARTITION BY dt."year"
                            ORDER BY dt."driver_points" DESC) AS rn
  FROM driver_totals dt
  JOIN "drivers"      d ON d."driver_id" = dt."driver_id"
),
constructor_totals AS (
  SELECT r."year",
         cs."constructor_id",
         SUM(cs."points") AS "constructor_points"
  FROM "constructor_standings" cs
  JOIN "races"                r ON r."race_id" = cs."race_id"
  GROUP BY r."year", cs."constructor_id"
),
top_constructors AS (
  SELECT ct."year",
         c."name" AS "constructor_name",
         ct."constructor_points",
         ROW_NUMBER() OVER (PARTITION BY ct."year"
                            ORDER BY ct."constructor_points" DESC) AS rn
  FROM constructor_totals ct
  JOIN "constructors"    c ON c."constructor_id" = ct."constructor_id"
)
SELECT td."year",
       td."driver_full_name",
       td."driver_points",
       tc."constructor_name",
       tc."constructor_points"
FROM top_drivers      td
JOIN top_constructors tc
  ON tc."year" = td."year"
WHERE td.rn = 1
  AND tc.rn = 1
ORDER BY td."year";