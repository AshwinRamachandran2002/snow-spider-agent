SELECT
    t."trip_id",
    t."duration_sec",
    t."start_date",
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name"           AS "route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    (YEAR(CURRENT_DATE()) - CAST(t."member_birth_year" AS INTEGER))   AS "age",
    CASE
        WHEN (YEAR(CURRENT_DATE()) - CAST(t."member_birth_year" AS INTEGER)) < 40  THEN 'Young (<40 Y.O)'
        WHEN (YEAR(CURRENT_DATE()) - CAST(t."member_birth_year" AS INTEGER)) <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                               AS "age_class",
    t."member_gender",
    r."name"                                                          AS "region_name"
FROM  "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS"         t
LEFT JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" s
       ON CAST(t."start_station_id" AS TEXT) = s."station_id"
LEFT JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_REGIONS"   r
       ON s."region_id" = r."region_id"
WHERE t."start_date" BETWEEN 1498867200000000     /* 2017-07-01 00:00:00 */
                        AND     1514687999000000  /* 2017-12-31 23:59:59 */
  AND t."start_station_name" IS NOT NULL
  AND t."member_birth_year"  IS NOT NULL
  AND t."member_gender"      IS NOT NULL
ORDER BY t."duration_sec" DESC NULLS LAST
LIMIT 5;