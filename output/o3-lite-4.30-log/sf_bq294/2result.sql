SELECT
    t."trip_id",
    t."duration_sec"                                                   AS "duration_seconds",
    t."start_date",
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name"            AS "route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    2024 - t."member_birth_year"                                       AS "member_current_age",
    CASE
        WHEN 2024 - t."member_birth_year" < 40  THEN 'Young (<40 Y.O)'
        WHEN 2024 - t."member_birth_year" <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE                                   'Senior Adult (>60 Y.O)'
    END                                                                AS "age_classification",
    t."member_gender",
    COALESCE(r."name", 'Unknown')                                      AS "start_station_region"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS            t
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO i
       ON CAST(t."start_station_id" AS TEXT) = i."station_id"
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS      r
       ON i."region_id" = r."region_id"
WHERE t."start_date" >= 1498867200000000   -- 2017‑07‑01 00:00:00 µs
  AND t."start_date" <  1514764800000000   -- 2018‑01‑01 00:00:00 µs
  AND t."start_station_name" IS NOT NULL
  AND t."member_birth_year"  IS NOT NULL
  AND t."member_gender"      IS NOT NULL
ORDER BY t."duration_sec" DESC NULLS LAST,
         t."trip_id"
LIMIT 5;