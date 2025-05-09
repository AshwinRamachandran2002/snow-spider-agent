SELECT
    t."trip_id",
    t."duration_sec",
    TO_TIMESTAMP_NTZ(t."start_date"/1000000)                          AS "start_date",
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name"           AS "route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    (YEAR(CURRENT_DATE) - t."member_birth_year")                      AS "age",
    CASE
        WHEN (YEAR(CURRENT_DATE) - t."member_birth_year") < 40  THEN 'Young (<40 Y.O)'
        WHEN (YEAR(CURRENT_DATE) - t."member_birth_year") <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                               AS "age_class",
    t."member_gender",
    r."name"                                                          AS "region_name"
FROM
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS            t
LEFT JOIN
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO     si
        ON TRY_TO_NUMBER(si."station_id") = t."start_station_id"
LEFT JOIN
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS          r
        ON r."region_id" = si."region_id"
WHERE
    TO_TIMESTAMP_NTZ(t."start_date"/1000000) BETWEEN '2017-07-01' AND '2017-12-31 23:59:59.999'
    AND t."start_station_name" IS NOT NULL
    AND t."member_birth_year"  IS NOT NULL
    AND t."member_gender"      IS NOT NULL
ORDER BY
    t."duration_sec" DESC NULLS LAST
LIMIT 5;