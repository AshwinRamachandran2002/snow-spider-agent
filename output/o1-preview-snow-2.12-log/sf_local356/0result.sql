SELECT
   d."full_name"
FROM
   (
       SELECT
           lp1."driver_id",
           SUM(CASE WHEN lp0."position" - lp1."position" > 0 THEN 1 ELSE 0 END) AS "overtakes_performed",
           SUM(CASE WHEN lp0."position" - lp1."position" < 0 THEN 1 ELSE 0 END) AS "overtakes_suffered"
       FROM
           "F1"."F1"."LAP_POSITIONS" lp1
       LEFT JOIN
           "F1"."F1"."LAP_POSITIONS" lp0
           ON lp1."driver_id" = lp0."driver_id"
           AND lp1."race_id" = lp0."race_id"
           AND lp1."lap" = lp0."lap" + 1
       GROUP BY
           lp1."driver_id"
   ) t
JOIN
   "F1"."F1"."DRIVERS_EXT" d
   ON t."driver_id" = d."driver_id"
WHERE
   t."overtakes_suffered" > t."overtakes_performed";