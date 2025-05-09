SELECT t."start_station_id" AS "Station_ID",
       COUNT(*) AS "Total_Trips",
       ROUND(COUNT(*) * 100.0 / (
           SELECT COUNT(*)
           FROM "AUSTIN"."AUSTIN_BIKESHARE"."BIKESHARE_TRIPS" t2
           JOIN "AUSTIN"."AUSTIN_BIKESHARE"."BIKESHARE_STATIONS" s2
             ON t2."start_station_id" = s2."station_id"
           WHERE s2."status" = 'active'
       ), 4) AS "Percentage_of_Total_Trips",
       ROUND(AVG(t."duration_minutes"), 4) AS "Average_Duration"
FROM "AUSTIN"."AUSTIN_BIKESHARE"."BIKESHARE_TRIPS" t
JOIN "AUSTIN"."AUSTIN_BIKESHARE"."BIKESHARE_STATIONS" s
  ON t."start_station_id" = s."station_id"
WHERE s."status" = 'active'
GROUP BY t."start_station_id"
ORDER BY "Total_Trips" DESC NULLS LAST
LIMIT 15;