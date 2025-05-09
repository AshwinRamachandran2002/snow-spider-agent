SELECT ROUND(
  (
    (
      SELECT COUNT(DISTINCT a."consecutive_number")::float
      FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."ACCIDENT_2015" a
      JOIN (
        SELECT "consecutive_number"
        FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."PERSON_2015"
        GROUP BY "consecutive_number"
        HAVING COUNT(DISTINCT "person_number") > 1
      ) p_multi
      ON a."consecutive_number" = p_multi."consecutive_number"
      JOIN (
        SELECT "consecutive_number"
        FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."PERSON_2015"
        WHERE "injury_severity" = 4
        GROUP BY "consecutive_number"
        HAVING COUNT(*) > 1
      ) p_severe
      ON a."consecutive_number" = p_severe."consecutive_number"
      WHERE a."month_of_crash" BETWEEN 1 AND 8
    ) * 100.0
    /
    (
      SELECT COUNT(DISTINCT "consecutive_number")::float
      FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."ACCIDENT_2015"
      WHERE "month_of_crash" BETWEEN 1 AND 8
    )
  ), 4
) AS "percentage_of_accidents";