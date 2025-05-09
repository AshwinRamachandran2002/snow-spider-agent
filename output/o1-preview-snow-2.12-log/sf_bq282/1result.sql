WITH "filtered_trips" AS (
    SELECT
        *,
        TRY_TO_NUMBER("start_station_id") AS "start_station_id_num",
        TRY_TO_NUMBER("end_station_id") AS "end_station_id_num"
    FROM
        AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE
        TRY_TO_NUMBER("start_station_id") IS NOT NULL
        AND TRY_TO_NUMBER("end_station_id") IS NOT NULL
        AND TRY_TO_NUMBER("start_station_id") != TRY_TO_NUMBER("end_station_id")
)
SELECT
    "start_stations"."council_district"
FROM
    "filtered_trips" AS "trips"
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS AS "start_stations"
        ON "trips"."start_station_id_num" = "start_stations"."station_id"
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS AS "end_stations"
        ON "trips"."end_station_id_num" = "end_stations"."station_id"
WHERE
    "start_stations"."council_district" = "end_stations"."council_district"
    AND "start_stations"."council_district" IS NOT NULL
GROUP BY
    "start_stations"."council_district"
ORDER BY
    COUNT(*) DESC NULLS LAST
LIMIT 1;