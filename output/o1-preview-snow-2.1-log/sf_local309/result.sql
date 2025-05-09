WITH driver_points AS (
  SELECT t."driver_id", t."year", SUM(t."points") AS "total_points"
  FROM (
    SELECT r."driver_id", ra."year", r."points"
    FROM "F1"."F1"."RESULTS" r
    JOIN "F1"."F1"."RACES" ra ON r."race_id" = ra."race_id"
    UNION ALL
    SELECT sr."driver_id", ra."year", sr."points"
    FROM "F1"."F1"."SPRINT_RESULTS" sr
    JOIN "F1"."F1"."RACES" ra ON sr."race_id" = ra."race_id"
  ) t
  GROUP BY t."driver_id", t."year"
),
constructor_points AS (
  SELECT t."constructor_id", t."year", SUM(t."points") AS "total_points"
  FROM (
    SELECT r."constructor_id", ra."year", r."points"
    FROM "F1"."F1"."RESULTS" r
    JOIN "F1"."F1"."RACES" ra ON r."race_id" = ra."race_id"
    UNION ALL
    SELECT sr."constructor_id", ra."year", sr."points"
    FROM "F1"."F1"."SPRINT_RESULTS" sr
    JOIN "F1"."F1"."RACES" ra ON sr."race_id" = ra."race_id"
  ) t
  GROUP BY t."constructor_id", t."year"
),
driver_rank AS (
  SELECT
    dp."driver_id",
    dp."year",
    dp."total_points",
    RANK() OVER (PARTITION BY dp."year" ORDER BY dp."total_points" DESC NULLS LAST) AS "rank"
  FROM driver_points dp
),
constructor_rank AS (
  SELECT
    cp."constructor_id",
    cp."year",
    cp."total_points",
    RANK() OVER (PARTITION BY cp."year" ORDER BY cp."total_points" DESC NULLS LAST) AS "rank"
  FROM constructor_points cp
),
driver_max AS (
  SELECT
    dr."driver_id",
    dr."year",
    dr."total_points"
  FROM driver_rank dr
  WHERE dr."rank" = 1
),
constructor_max AS (
  SELECT
    cr."constructor_id",
    cr."year",
    cr."total_points"
  FROM constructor_rank cr
  WHERE cr."rank" = 1
),
drivers_with_names AS (
  SELECT dm."year", d."full_name" AS "Driver_Full_Name"
  FROM driver_max dm
  JOIN "F1"."F1"."DRIVERS" d ON dm."driver_id" = d."driver_id"
),
constructors_with_names AS (
  SELECT cm."year", c."name" AS "Constructor_Name"
  FROM constructor_max cm
  JOIN "F1"."F1"."CONSTRUCTORS" c ON cm."constructor_id" = c."constructor_id"
)
SELECT
  dwn."year" AS "Year",
  dwn."Driver_Full_Name",
  cwn."Constructor_Name"
FROM drivers_with_names dwn
JOIN constructors_with_names cwn ON dwn."year" = cwn."year"
ORDER BY dwn."year" ASC;