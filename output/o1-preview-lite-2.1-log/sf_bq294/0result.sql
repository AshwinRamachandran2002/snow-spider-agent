SELECT
  t."trip_id",
  t."duration_sec",
  TO_TIMESTAMP(t."start_date" / 1000000) AS "start_date",
  t."start_station_name",
  t."start_station_name" || ' - ' || t."end_station_name" AS "route",
  t."bike_number",
  t."subscriber_type",
  t."member_birth_year",
  EXTRACT(YEAR FROM TO_TIMESTAMP(t."start_date" / 1000000)) - t."member_birth_year" AS "age",
  CASE
    WHEN EXTRACT(YEAR FROM TO_TIMESTAMP(t."start_date" / 1000000)) - t."member_birth_year" < 40 THEN 'Young (<40 Y.O)'
    WHEN EXTRACT(YEAR FROM TO_TIMESTAMP(t."start_date" / 1000000)) - t."member_birth_year" BETWEEN 40 AND 60 THEN 'Adult (40-60 Y.O)'
    WHEN EXTRACT(YEAR FROM TO_TIMESTAMP(t."start_date" / 1000000)) - t."member_birth_year" > 60 THEN 'Senior Adult (>60 Y.O)'
    ELSE 'Unknown'
  END AS "age_class",
  t."member_gender",
  r."name" AS "region_name"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
  ON t."start_station_id" = s."station_id"
JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
  ON s."region_id" = r."region_id"
WHERE TO_DATE(TO_TIMESTAMP(t."start_date" / 1000000)) BETWEEN DATE '2017-07-01' AND DATE '2017-12-31'
  AND t."start_station_name" IS NOT NULL
  AND t."member_birth_year" IS NOT NULL
  AND t."member_gender" IS NOT NULL
ORDER BY t."duration_sec" DESC NULLS LAST
LIMIT 5;