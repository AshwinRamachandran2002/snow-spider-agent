SELECT DISTINCT d."full_name" AS "name"
FROM (
  SELECT lp_current."driver_id", COUNT(*) AS "times_gained"
  FROM "lap_positions" lp_current
  JOIN "lap_positions" lp_previous
    ON lp_current."driver_id" = lp_previous."driver_id"
   AND lp_current."race_id" = lp_previous."race_id"
   AND lp_current."lap" = lp_previous."lap" + 1
  WHERE lp_current."position" < lp_previous."position"
  GROUP BY lp_current."driver_id"
) gains
JOIN (
  SELECT lp_current."driver_id", COUNT(*) AS "times_lost"
  FROM "lap_positions" lp_current
  JOIN "lap_positions" lp_previous
    ON lp_current."driver_id" = lp_previous."driver_id"
   AND lp_current."race_id" = lp_previous."race_id"
   AND lp_current."lap" = lp_previous."lap" + 1
  WHERE lp_current."position" > lp_previous."position"
  GROUP BY lp_current."driver_id"
) losses ON gains."driver_id" = losses."driver_id"
JOIN "drivers" d ON gains."driver_id" = d."driver_id"
WHERE losses."times_lost" > gains."times_gained"
ORDER BY d."full_name";