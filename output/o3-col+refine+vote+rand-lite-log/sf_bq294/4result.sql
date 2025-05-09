SELECT
    t."trip_id",
    t."duration_sec",
    t."start_date",
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name"          AS "route",
    t."bike_number",
    t."subscriber_type",
    CAST(TRY_CAST(t."member_birth_year" AS INT) AS INT)              AS "member_birth_year",
    2024 - CAST(TRY_CAST(t."member_birth_year" AS INT) AS INT)       AS "current_age",
    CASE
        WHEN 2024 - CAST(TRY_CAST(t."member_birth_year" AS INT) AS INT) < 40
             THEN 'Young (<40 Y.O)'
        WHEN 2024 - CAST(TRY_CAST(t."member_birth_year" AS INT) AS INT) BETWEEN 40 AND 60
             THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                              AS "age_class",
    t."member_gender",
    r."name"                                                         AS "region_name"
FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS         t
LEFT  JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
       ON t."start_station_id" = TRY_CAST(s."station_id" AS INT)
LEFT  JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS     r
       ON s."region_id" = r."region_id"
WHERE  t."start_date" BETWEEN 1498867200000000 AND 1514764799000000   -- 2017-07-01 to 2017-12-31
  AND  t."start_station_name" IS NOT NULL
  AND  t."member_gender" IS NOT NULL
  AND  TRY_CAST(t."member_birth_year" AS INT) IS NOT NULL
ORDER BY t."duration_sec" DESC NULLS LAST
LIMIT 5;