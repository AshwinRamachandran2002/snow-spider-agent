SELECT
    t."trip_id",
    t."duration_sec",
    TO_DATE(TO_TIMESTAMP(t."start_date" / 1000000)) AS "start_date",
    t."start_station_name",
    t."start_station_name" || ' - ' || t."end_station_name" AS "route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    EXTRACT(year FROM CURRENT_DATE) - t."member_birth_year" AS "member_current_age",
    CASE
        WHEN EXTRACT(year FROM CURRENT_DATE) - t."member_birth_year" < 40 THEN 'Young (<40 Y.O)'
        WHEN EXTRACT(year FROM CURRENT_DATE) - t."member_birth_year" BETWEEN 40 AND 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END AS "age_classification",
    t."member_gender",
    r."name" AS "region_name"
FROM
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
JOIN
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
    ON t."start_station_id" = s."station_id"
JOIN
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
    ON s."region_id" = r."region_id"
WHERE
    t."start_station_name" IS NOT NULL
    AND t."member_birth_year" IS NOT NULL
    AND t."member_gender" IS NOT NULL
    AND t."member_gender" <> ''
    AND TO_TIMESTAMP(t."start_date" / 1000000) >= '2017-07-01'
    AND TO_TIMESTAMP(t."start_date" / 1000000) <= '2017-12-31'
ORDER BY
    t."duration_sec" DESC NULLS LAST
LIMIT 5;