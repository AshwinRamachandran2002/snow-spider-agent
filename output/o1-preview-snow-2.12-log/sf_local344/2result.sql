WITH races_with_pit_data AS (
  SELECT "race_id"
  FROM "F1"."F1"."RACES_EXT"
  WHERE "is_pit_data_available" = 1
),
driver_positions AS (
  SELECT
    lt."race_id",
    lt."lap",
    lt."driver_id",
    lt."position"
  FROM "F1"."F1"."LAP_TIMES" lt
  WHERE lt."race_id" IN (SELECT "race_id" FROM races_with_pit_data)
),
position_changes AS (
  SELECT
    curr."race_id",
    curr."lap",
    curr."driver_id" AS "overtaking_driver_id",
    curr."position" AS "curr_position",
    prev."position" AS "prev_position"
  FROM driver_positions curr
  JOIN driver_positions prev
    ON curr."race_id" = prev."race_id"
    AND curr."driver_id" = prev."driver_id"
    AND curr."lap" = prev."lap" + 1
  WHERE curr."position" < prev."position"
),
overtakes AS (
  SELECT
    pc."race_id",
    pc."lap",
    pc."overtaking_driver_id",
    pc."curr_position",
    pc."prev_position",
    od."driver_id" AS "overtaken_driver_id"
  FROM position_changes pc
  JOIN driver_positions od
    ON pc."race_id" = od."race_id"
    AND od."lap" = pc."lap"
    AND od."position" = pc."curr_position" + 1
),
classified_overtakes AS (
  SELECT
    o.*,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM "F1"."F1"."RETIREMENTS" r
        WHERE r."race_id" = o."race_id"
          AND r."driver_id" = o."overtaken_driver_id"
          AND r."lap" = o."lap"
      ) THEN 'R'
      WHEN EXISTS (
        SELECT 1 FROM "F1"."F1"."PIT_STOPS" ps
        WHERE ps."race_id" = o."race_id"
          AND ps."driver_id" = o."overtaken_driver_id"
          AND ps."lap" IN (o."lap", o."lap" - 1)
      ) THEN 'P'
      WHEN o."lap" = 1 AND ABS(r1."grid" - r2."grid") <= 2 THEN 'S'
      ELSE 'T'
    END AS "Overtake_Type"
  FROM overtakes o
  LEFT JOIN "F1"."F1"."RESULTS" r1
    ON o."race_id" = r1."race_id" AND o."overtaking_driver_id" = r1."driver_id"
  LEFT JOIN "F1"."F1"."RESULTS" r2
    ON o."race_id" = r2."race_id" AND o."overtaken_driver_id" = r2."driver_id"
  WHERE r1."grid" IS NOT NULL AND r2."grid" IS NOT NULL
)
SELECT "Overtake_Type", COUNT(*) AS "Count"
FROM classified_overtakes
GROUP BY "Overtake_Type";