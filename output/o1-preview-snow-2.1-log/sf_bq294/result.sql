SELECT
    t."trip_id",
    t."duration_sec",
    DATE_TRUNC('day', TO_TIMESTAMP_NTZ(t."start_date" / 1000000)) AS "Start date",
    t."start_station_name",
    CONCAT(t."start_station_name", ' - ', t."end_station_name") AS "Route",
    t."bike_number",
    t."subscriber_type",
    t."member_birth_year",
    EXTRACT(year FROM DATE_TRUNC('day', TO_TIMESTAMP_NTZ(t."start_date" / 1000000))) - t."member_birth_year" AS "Current age",
    CASE
        WHEN EXTRACT(year FROM DATE_TRUNC('day', TO_TIMESTAMP_NTZ(t."start_date" / 1000000))) - t."member_birth_year" < 40 THEN 'Young (<40 Y.O)'
        WHEN EXTRACT(year FROM DATE_TRUNC('day', TO_TIMESTAMP_NTZ(t."start_date" / 1000000))) - t."member_birth_year" BETWEEN 40 AND 60 THEN 'Adult (40-60 Y.O)'
        WHEN EXTRACT(year FROM DATE_TRUNC('day', TO_TIMESTAMP_NTZ(t."start_date" / 1000000))) - t."member_birth_year" > 60 THEN 'Senior Adult (>60 Y.O)'
    END AS "Age classification",
    t."member_gender" AS "Gender",
    r."name" AS "Region name"
FROM
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s ON t."start_station_id" = s."station_id"
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r ON s."region_id" = r."region_id"
WHERE
    t."start_station_name" IS NOT NULL AND TRIM(t."start_station_name") <> ''
    AND t."member_birth_year" IS NOT NULL
    AND t."member_gender" IS NOT NULL AND TRIM(t."member_gender") <> ''
    AND TO_TIMESTAMP_NTZ(t."start_date" / 1000000) >= '2017-07-01'
    AND TO_TIMESTAMP_NTZ(t."start_date" / 1000000) < '2018-01-01'
ORDER BY
    t."duration_sec" DESC NULLS LAST
LIMIT 5;