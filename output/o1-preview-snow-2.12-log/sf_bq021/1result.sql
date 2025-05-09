WITH bike_routes AS (
    SELECT
        ROUND("start_station_latitude", 3) AS "start_lat",
        ROUND("start_station_longitude", 3) AS "start_lon",
        ROUND("end_station_latitude", 3) AS "end_lat",
        ROUND("end_station_longitude", 3) AS "end_lon",
        COUNT(*) AS "trip_count",
        AVG("tripduration") AS "avg_bike_duration"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE
        "starttime" >= 1451606400000000 AND "starttime" < 1483228800000000
        AND "start_station_latitude" != 0 AND "start_station_longitude" != 0
        AND "end_station_latitude" != 0 AND "end_station_longitude" != 0
    GROUP BY "start_lat", "start_lon", "end_lat", "end_lon"
),
taxi_routes AS (
    SELECT
        ROUND("pickup_latitude", 3) AS "start_lat",
        ROUND("pickup_longitude", 3) AS "start_lon",
        ROUND("dropoff_latitude", 3) AS "end_lat",
        ROUND("dropoff_longitude", 3) AS "end_lon",
        AVG(("dropoff_datetime" - "pickup_datetime") / 1e6) AS "avg_taxi_duration"
    FROM NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE
        "pickup_datetime" >= 1451606400000000 AND "pickup_datetime" < 1483228800000000
        AND "pickup_latitude" != 0 AND "pickup_longitude" != 0
        AND "dropoff_latitude" != 0 AND "dropoff_longitude" != 0
        AND "dropoff_datetime" > "pickup_datetime"
    GROUP BY "start_lat", "start_lon", "end_lat", "end_lon"
),
joined_routes AS (
    SELECT
        br."start_lat",
        br."start_lon",
        br."end_lat",
        br."end_lon",
        br."trip_count",
        br."avg_bike_duration",
        tr."avg_taxi_duration"
    FROM bike_routes br
    INNER JOIN taxi_routes tr
        ON br."start_lat" = tr."start_lat"
            AND br."start_lon" = tr."start_lon"
            AND br."end_lat" = tr."end_lat"
            AND br."end_lon" = tr."end_lon"
),
filtered_routes AS (
    SELECT *
    FROM joined_routes
    WHERE "trip_count" > 0  -- Ensure we have trips
        AND "avg_bike_duration" < "avg_taxi_duration"
),
top_bike_routes AS (
    SELECT *
    FROM filtered_routes
    ORDER BY "trip_count" DESC NULLS LAST
    LIMIT 20
),
start_station_names AS (
    SELECT
        ROUND("start_station_latitude", 3) AS "start_lat",
        ROUND("start_station_longitude", 3) AS "start_lon",
        "start_station_name",
        COUNT(*) AS "station_trip_count"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE
        "starttime" >= 1451606400000000 AND "starttime" < 1483228800000000
        AND "start_station_latitude" != 0 AND "start_station_longitude" != 0
    GROUP BY "start_lat", "start_lon", "start_station_name"
),
most_common_start_station AS (
    SELECT
        "start_lat",
        "start_lon",
        "start_station_name"
    FROM (
        SELECT
            "start_lat",
            "start_lon",
            "start_station_name",
            ROW_NUMBER() OVER (PARTITION BY "start_lat", "start_lon" ORDER BY "station_trip_count" DESC NULLS LAST) AS rn
        FROM start_station_names
    )
    WHERE rn = 1
)
SELECT
    mcss."start_station_name"
FROM top_bike_routes tbr
JOIN most_common_start_station mcss
    ON tbr."start_lat" = mcss."start_lat"
    AND tbr."start_lon" = mcss."start_lon"
ORDER BY tbr."avg_bike_duration" DESC NULLS LAST
LIMIT 1;