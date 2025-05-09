SELECT
    bt."trip_id",
    bt."duration_sec",
    TO_TIMESTAMP(bt."start_date", 6)                                            AS "start_date",
    bt."start_station_name",
    bt."start_station_name" || ' - ' || bt."end_station_name"                  AS "route",
    bt."bike_number",
    bt."subscriber_type",
    bt."member_birth_year",
    YEAR(CURRENT_DATE()) - CAST(bt."member_birth_year" AS INT)                 AS "current_age",
    CASE
        WHEN YEAR(CURRENT_DATE()) - CAST(bt."member_birth_year" AS INT) < 40  THEN 'Young (<40 Y.O)'
        WHEN YEAR(CURRENT_DATE()) - CAST(bt."member_birth_year" AS INT) BETWEEN 40 AND 60
                                                                             THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                                        AS "age_class",
    bt."member_gender",
    rg."name"                                                                  AS "region_name"
FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_TRIPS"            bt
LEFT   JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_STATION_INFO" si
       ON bt."start_station_name" = si."name"
LEFT   JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_REGIONS"      rg
       ON si."region_id" = rg."region_id"
WHERE  bt."start_date" BETWEEN 1498867200000000 AND 1514764799000000              -- 2017-07-01 .. 2017-12-31 (µs)
  AND  bt."start_station_name" IS NOT NULL
  AND  bt."member_birth_year"  IS NOT NULL
  AND  bt."member_gender"      IS NOT NULL
ORDER BY bt."duration_sec" DESC NULLS LAST
LIMIT 5;