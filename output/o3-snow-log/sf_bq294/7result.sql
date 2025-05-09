SELECT
    t."trip_id",
    t."duration_sec",
    TO_TIMESTAMP_NTZ(t."start_date" / 1000000)                         AS "start_datetime",
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name"            AS "route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    (YEAR(CURRENT_DATE) - t."member_birth_year")                       AS "age",
    CASE
        WHEN (YEAR(CURRENT_DATE) - t."member_birth_year") < 40  THEN 'Young (<40 Y.O)'
        WHEN (YEAR(CURRENT_DATE) - t."member_birth_year") <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                                AS "age_class",
    t."member_gender",
    r."name"                                                           AS "region_name"
FROM  SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS         t
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
       ON s."station_id" = TO_VARCHAR(t."start_station_id")
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS      r
       ON r."region_id" = s."region_id"
WHERE  TO_DATE(TO_TIMESTAMP_NTZ(t."start_date" / 1000000))
          BETWEEN '2017-07-01' AND '2017-12-31'
  AND  t."start_station_name" IS NOT NULL
  AND  t."member_birth_year"   IS NOT NULL
  AND  t."member_gender"       IS NOT NULL
ORDER BY t."duration_sec" DESC NULLS LAST
LIMIT 5;