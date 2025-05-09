WITH driver_positions AS (
  SELECT "race_id", "driver_id", "lap", "position"
  FROM "lap_positions"
  WHERE "lap" BETWEEN 0 AND 5
),
position_changes AS (
  SELECT 
    dp_current."race_id",
    dp_current."driver_id",
    dp_current."lap",
    dp_current."position" AS current_position,
    dp_previous."position" AS previous_position,
    (dp_previous."position" - dp_current."position") AS positions_gained
  FROM driver_positions dp_current
  JOIN driver_positions dp_previous
    ON dp_current."race_id" = dp_previous."race_id"
   AND dp_current."driver_id" = dp_previous."driver_id"
   AND dp_current."lap" = dp_previous."lap" + 1
),
numbers(n) AS (
  SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
  SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
  SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
  SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
),
expanded_overtakes AS (
  SELECT 
    pc."race_id",
    pc."driver_id",
    pc."lap",
    pc.current_position + n.n - 1 AS overtake_position
  FROM position_changes pc
  JOIN numbers n ON n.n <= pc.positions_gained
  WHERE pc.positions_gained > 0
),
overtakes AS (
  SELECT 
    eo."driver_id",
    eo."race_id",
    eo."lap",
    eo.overtake_position,
    dp_prev."driver_id" AS overtaken_driver_id
  FROM expanded_overtakes eo
  JOIN driver_positions dp_prev
    ON eo."race_id" = dp_prev."race_id"
   AND dp_prev."lap" = eo."lap" - 1
   AND dp_prev."position" = eo.overtake_position
)
SELECT overtake_type, COUNT(*) AS num_overtakes
FROM (
  SELECT 
    overtakes."driver_id",
    overtakes."lap",
    CASE
      WHEN r."driver_id" IS NOT NULL THEN 'Overtake due to retirement'
      WHEN ps."driver_id" IS NOT NULL THEN 'Overtake due to pit stop'
      ELSE 'On-track overtake'
    END AS overtake_type
  FROM overtakes
  LEFT JOIN "pit_stops" ps
    ON overtakes."race_id" = ps."race_id"
   AND overtakes.overtaken_driver_id = ps."driver_id"
   AND ps."lap" = overtakes."lap"
  LEFT JOIN "retirements" r
    ON overtakes."race_id" = r."race_id"
   AND overtakes.overtaken_driver_id = r."driver_id"
   AND r."lap" = overtakes."lap"
)
GROUP BY overtake_type;