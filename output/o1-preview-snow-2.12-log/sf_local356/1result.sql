SELECT de."full_name"
FROM "F1"."F1"."LAP_POSITIONS" AS lp1
JOIN "F1"."F1"."LAP_POSITIONS" AS lp2
  ON lp1."driver_id" = lp2."driver_id"
  AND lp1."race_id" = lp2."race_id"
  AND lp1."lap" + 1 = lp2."lap"
JOIN "F1"."F1"."DRIVERS_EXT" AS de
  ON lp1."driver_id" = de."driver_id"
WHERE lp1."position" IS NOT NULL
  AND lp2."position" IS NOT NULL
  AND lp1."lap" > 0
  AND lp2."lap" > 0
GROUP BY de."full_name"
HAVING COUNT(CASE WHEN lp2."position" > lp1."position" THEN 1 END) > COUNT(CASE WHEN lp2."position" < lp1."position" THEN 1 END);