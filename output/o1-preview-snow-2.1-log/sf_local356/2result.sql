SELECT d."full_name"
FROM (
  SELECT "driver_id"
  FROM (
    SELECT "driver_id",
           SUM(CASE WHEN "delta_position" < 0 THEN 1 ELSE 0 END) AS "overtakes",
           SUM(CASE WHEN "delta_position" > 0 THEN 1 ELSE 0 END) AS "times_overtaken"
    FROM (
      SELECT lp1."driver_id",
             (lp2."position" - lp1."position") AS "delta_position"
      FROM "F1"."F1"."LAP_POSITIONS" lp1
      JOIN "F1"."F1"."LAP_POSITIONS" lp2
        ON lp1."driver_id" = lp2."driver_id"
       AND lp1."race_id" = lp2."race_id"
       AND lp1."lap" = lp2."lap" + 1
    ) sub
    GROUP BY "driver_id"
  ) totals
  WHERE "times_overtaken" > "overtakes"
) drivers
JOIN "F1"."F1"."DRIVERS" d
  ON drivers."driver_id" = d."driver_id";