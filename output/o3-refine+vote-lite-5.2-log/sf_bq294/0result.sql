SELECT
    t."trip_id",
    t."duration_sec",
    TO_TIMESTAMP_NTZ(t."start_date" / 1000000)                      AS "start_date",
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name"        AS "route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    DATE_PART('year', CURRENT_DATE) - t."member_birth_year"        AS "member_age",
    CASE
        WHEN DATE_PART('year', CURRENT_DATE) - t."member_birth_year" < 40  THEN 'Young (<40 Y.O)'
        WHEN DATE_PART('year', CURRENT_DATE) - t."member_birth_year" <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE                                                              'Senior Adult (>60 Y.O)'
    END                                                             AS "age_class",
    t."member_gender",
    r."name"                                                        AS "region_name"
FROM  SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS          t
LEFT  JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
       ON si."station_id" = t."start_station_id"::VARCHAR
LEFT  JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS   r
       ON r."region_id" = si."region_id"
WHERE t."start_station_name" IS NOT NULL
  AND t."member_birth_year"  IS NOT NULL
  AND t."member_gender"      IS NOT NULL
  AND TO_TIMESTAMP_NTZ(t."start_date" / 1000000) >= '2017-07-01'::TIMESTAMP
  AND TO_TIMESTAMP_NTZ(t."start_date" / 1000000) <  '2018-01-01'::TIMESTAMP
ORDER BY t."duration_sec" DESC NULLS LAST, t."trip_id"
LIMIT 5;