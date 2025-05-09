SELECT 
  t."trip_id", 
  t."duration_sec", 
  TO_TIMESTAMP_NTZ(t."start_date"/1e6) AS "start_date", 
  t."start_station_name", 
  CONCAT(t."start_station_name", ' - ', t."end_station_name") AS "route", 
  t."bike_number", 
  t."subscriber_type", 
  t."member_birth_year", 
  (2023 - t."member_birth_year") AS "current_age", 
  CASE 
    WHEN (2023 - t."member_birth_year") < 40 THEN 'Young (<40 Y.O)' 
    WHEN (2023 - t."member_birth_year") BETWEEN 40 AND 60 THEN 'Adult (40-60 Y.O)' 
    WHEN (2023 - t."member_birth_year") > 60 THEN 'Senior Adult (>60 Y.O)' 
    ELSE 'Unknown' 
  END AS "age_classification", 
  t."member_gender", 
  r."name" AS "region_name"
FROM 
  "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS" AS t
JOIN 
  "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" AS s
  ON t."start_station_id"::VARCHAR = s."station_id"
JOIN 
  "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_REGIONS" AS r
  ON s."region_id" = r."region_id"
WHERE 
  TO_TIMESTAMP_NTZ(t."start_date"/1e6) BETWEEN '2017-07-01' AND '2017-12-31'
  AND t."start_station_name" IS NOT NULL AND TRIM(t."start_station_name") <> ''
  AND t."member_birth_year" IS NOT NULL AND t."member_birth_year" BETWEEN 1900 AND 2005
  AND t."member_gender" IS NOT NULL AND TRIM(t."member_gender") <> ''
ORDER BY 
  t."duration_sec" DESC NULLS LAST
LIMIT 5;