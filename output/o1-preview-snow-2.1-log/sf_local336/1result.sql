WITH lap_positions AS (
  SELECT "race_id", "lap", "driver_id", "position"
  FROM F1.F1.LAP_POSITIONS
  WHERE "lap" BETWEEN 0 AND 5
),
position_changes AS (
  SELECT
    l1."race_id",
    l1."driver_id",
    l2."lap",
    l1."position" AS "position_l_minus1",
    l2."position" AS "position_l"
  FROM lap_positions l1
  JOIN lap_positions l2
    ON l1."race_id" = l2."race_id"
    AND l1."driver_id" = l2."driver_id"
    AND l2."lap" = l1."lap" + 1
  WHERE l1."lap" BETWEEN 0 AND 4
),
overtakes AS (
  SELECT
    pc."race_id",
    pc."driver_id" AS "overtaking_driver_id",
    pc."lap",
    pc."position_l_minus1",
    pc."position_l",
    (pc."position_l_minus1" - pc."position_l") AS "positions_gained"
  FROM position_changes pc
  WHERE pc."position_l" < pc."position_l_minus1"
),
grid_positions AS (
  SELECT "race_id", "driver_id", "grid"
  FROM F1.F1.RESULTS
),
retirements AS (
  SELECT "race_id", "driver_id", "lap" AS "retirement_lap"
  FROM F1.F1.RETIREMENTS
),
pit_stops AS (
  SELECT "race_id", "driver_id", "lap" AS "pit_lap"
  FROM F1.F1.PIT_STOPS
),
overtaken_drivers AS (
  SELECT
    o."race_id",
    o."lap",
    o."overtaking_driver_id",
    od."driver_id" AS "overtaken_driver_id",
    o."position_l_minus1",
    o."position_l",
    od."position_l_minus1" AS "overtaken_position_l_minus1",
    od."position_l" AS "overtaken_position_l"
  FROM overtakes o
  JOIN position_changes od
    ON o."race_id" = od."race_id"
    AND o."lap" = od."lap"
    AND od."driver_id" != o."overtaking_driver_id"
    AND od."position_l_minus1" < o."position_l_minus1"
    AND od."position_l" >= o."position_l"
),
classified_overtakes AS (
  SELECT
    od."race_id",
    od."lap",
    od."overtaking_driver_id",
    od."overtaken_driver_id",
    CASE
      WHEN r."driver_id" IS NOT NULL AND r."retirement_lap" = od."lap" THEN 'R'
      WHEN p."driver_id" IS NOT NULL AND p."pit_lap" = od."lap" THEN 'P'
      WHEN od."lap" = 1 AND ABS(g1."grid" - g2."grid") <= 2 THEN 'S'
      ELSE 'T'
    END AS "overtake_type"
  FROM overtaken_drivers od
  LEFT JOIN retirements r
    ON od."race_id" = r."race_id"
    AND od."overtaken_driver_id" = r."driver_id"
    AND od."lap" = r."retirement_lap"
  LEFT JOIN pit_stops p
    ON od."race_id" = p."race_id"
    AND od."overtaken_driver_id" = p."driver_id"
    AND od."lap" = p."pit_lap"
  LEFT JOIN grid_positions g1
    ON od."race_id" = g1."race_id"
    AND od."overtaking_driver_id" = g1."driver_id"
  LEFT JOIN grid_positions g2
    ON od."race_id" = g2."race_id"
    AND od."overtaken_driver_id" = g2."driver_id"
  WHERE od."lap" BETWEEN 1 AND 5
)
SELECT
  "overtake_type" AS "Type",
  COUNT(DISTINCT CONCAT("race_id", '_', "lap", '_', "overtaking_driver_id", '_', "overtaken_driver_id")) AS "Number_of_Overtakes"
FROM classified_overtakes
GROUP BY "overtake_type";