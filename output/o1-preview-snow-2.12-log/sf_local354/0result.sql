WITH driver_race_results AS (
  SELECT 
    "RESULTS"."driver_id",
    "RACES"."year",
    "RACES"."date" AS "race_date",
    "RESULTS"."constructor_id",
    "RESULTS"."race_id"
  FROM "F1"."F1"."RESULTS" AS "RESULTS"
  INNER JOIN "F1"."F1"."RACES" AS "RACES"
    ON "RESULTS"."race_id" = "RACES"."race_id"
  WHERE "RACES"."year" BETWEEN 1950 AND 1959
),
races_per_driver_season AS (
  SELECT 
    "driver_id",
    "year",
    COUNT(DISTINCT "race_id") AS "race_count"
  FROM driver_race_results
  GROUP BY "driver_id", "year"
  HAVING COUNT(DISTINCT "race_id") >= 2
),
driver_races_filtered AS (
  SELECT
    drs.*
  FROM driver_race_results drs
  INNER JOIN races_per_driver_season rpd
    ON drs."driver_id" = rpd."driver_id" AND drs."year" = rpd."year"
),
driver_races_with_order AS (
  SELECT
    drf.*,
    ROW_NUMBER() OVER (PARTITION BY drf."driver_id", drf."year" ORDER BY drf."race_date", drf."race_id") AS race_order
  FROM driver_races_filtered drf
),
first_and_last_races AS (
  SELECT
    drswo."driver_id",
    drswo."year",
    MIN(drswo.race_order) AS first_race_order,
    MAX(drswo.race_order) AS last_race_order
  FROM driver_races_with_order drswo
  GROUP BY drswo."driver_id", drswo."year"
),
constructors_at_first_last_races AS (
  SELECT
    falr."driver_id",
    falr."year",
    fr."constructor_id" AS "first_constructor_id",
    lr."constructor_id" AS "last_constructor_id"
  FROM first_and_last_races falr
  INNER JOIN driver_races_with_order fr
    ON falr."driver_id" = fr."driver_id"
    AND falr."year" = fr."year"
    AND falr.first_race_order = fr.race_order
  INNER JOIN driver_races_with_order lr
    ON falr."driver_id" = lr."driver_id"
    AND falr."year" = lr."year"
    AND falr.last_race_order = lr.race_order
),
drivers_same_constructor AS (
  SELECT
    "driver_id",
    "year"
  FROM constructors_at_first_last_races
  WHERE "first_constructor_id" = "last_constructor_id"
)
SELECT DISTINCT "DRIVERS"."full_name" AS "name"
FROM drivers_same_constructor dsc
INNER JOIN "F1"."F1"."DRIVERS" AS "DRIVERS"
  ON dsc."driver_id" = "DRIVERS"."driver_id"
ORDER BY "name";