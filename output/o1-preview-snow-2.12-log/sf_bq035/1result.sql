WITH trip_distances AS (
    SELECT 
        t."bike_number",
        ST_DISTANCE(
            ST_MAKEPOINT(start_station."longitude", start_station."latitude"),
            ST_MAKEPOINT(end_station."longitude", end_station."latitude")
        ) AS "trip_distance_meters"
    FROM "SAN_FRANCISCO"."SAN_FRANCISCO"."BIKESHARE_TRIPS" t
    INNER JOIN "SAN_FRANCISCO"."SAN_FRANCISCO"."BIKESHARE_STATIONS" start_station
        ON t."start_station_id" = start_station."station_id"
    INNER JOIN "SAN_FRANCISCO"."SAN_FRANCISCO"."BIKESHARE_STATIONS" end_station
        ON t."end_station_id" = end_station."station_id"
    WHERE t."bike_number" IS NOT NULL
)
SELECT
    "bike_number",
    ROUND(SUM("trip_distance_meters"), 4) AS "total_distance_meters"
FROM trip_distances
GROUP BY "bike_number"
ORDER BY "bike_number";