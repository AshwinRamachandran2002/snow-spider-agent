SELECT
    t."trip_id" AS "Trip ID",
    t."duration_sec" AS "Duration in seconds",
    TO_DATE(TO_TIMESTAMP_NTZ(t."start_date" / 1e6)) AS "Start date",
    t."start_station_name" AS "Start station name",
    t."start_station_name" || ' - ' || t."end_station_name" AS "Route",
    t."bike_number" AS "Bike number",
    t."subscriber_type" AS "Subscriber type",
    t."member_birth_year" AS "Member's birth year",
    EXTRACT(YEAR FROM CURRENT_DATE) - t."member_birth_year" AS "Current age",
    CASE
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - t."member_birth_year" < 40 THEN 'Young (<40 Y.O)'
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - t."member_birth_year" BETWEEN 40 AND 60 THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END AS "Age classification",
    t."member_gender" AS "Gender",
    r."name" AS "Region name"
FROM
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
        ON t."start_station_id" = s."station_id"
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
        ON s."region_id" = r."region_id"
WHERE
    TO_DATE(TO_TIMESTAMP_NTZ(t."start_date" / 1e6)) BETWEEN '2017-07-01' AND '2017-12-31'
    AND t."start_station_name" IS NOT NULL
    AND t."member_birth_year" IS NOT NULL
    AND t."member_gender" IS NOT NULL
ORDER BY
    t."duration_sec" DESC NULLS LAST
LIMIT 5;