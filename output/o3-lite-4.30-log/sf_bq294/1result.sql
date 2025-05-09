SELECT
    t."trip_id"                                                AS trip_id,
    t."duration_sec"                                           AS duration_seconds,
    TO_TIMESTAMP_LTZ(t."start_date" / 1000000)                 AS start_date,
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name"    AS route,
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    DATE_PART('year', CURRENT_DATE) - t."member_birth_year"    AS member_current_age,
    CASE
        WHEN DATE_PART('year', CURRENT_DATE) - t."member_birth_year" < 40  THEN 'Young (<40 Y.O)'
        WHEN DATE_PART('year', CURRENT_DATE) - t."member_birth_year" <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                       AS age_classification,
    t."member_gender",
    COALESCE(r."name", 'Unknown')                              AS start_station_region
FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS"            t
LEFT JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" s
       ON TO_VARCHAR(t."start_station_id") = s."station_id"
LEFT JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_REGIONS"      r
       ON s."region_id" = r."region_id"
WHERE TO_TIMESTAMP_LTZ(t."start_date" / 1000000) BETWEEN '2017-07-01 00:00:00' AND '2017-12-31 23:59:59'
  AND t."start_station_name" IS NOT NULL
  AND t."member_birth_year" IS NOT NULL
  AND t."member_gender" IS NOT NULL
ORDER BY t."duration_sec" DESC NULLS LAST
LIMIT 5;