WITH bike_routes AS (
    SELECT 
        ROUND("start_station_latitude", 3) AS "start_latitude",
        ROUND("start_station_longitude", 3) AS "start_longitude",
        ROUND("end_station_latitude", 3) AS "end_latitude",
        ROUND("end_station_longitude", 3) AS "end_longitude",
        COUNT(*) AS "trip_count",
        AVG("tripduration") AS "avg_bike_duration"
    FROM 
        NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE 
        "starttime" BETWEEN 1451606400000000 AND 1483228800000000 AND
        "start_station_latitude" IS NOT NULL AND "start_station_longitude" IS NOT NULL AND
        "end_station_latitude" IS NOT NULL AND "end_station_longitude" IS NOT NULL AND
        "tripduration" > 60 AND "tripduration" < 7200  -- Trip duration between 1 minute and 2 hours
    GROUP BY 
        "start_latitude", "start_longitude", "end_latitude", "end_longitude"
    HAVING
        COUNT(*) > 0
    ORDER BY 
        "trip_count" DESC NULLS LAST
    LIMIT 20
),
taxi_routes AS (
    SELECT 
        ROUND("pickup_latitude", 3) AS "start_latitude",
        ROUND("pickup_longitude", 3) AS "start_longitude",
        ROUND("dropoff_latitude", 3) AS "end_latitude",
        ROUND("dropoff_longitude", 3) AS "end_longitude",
        AVG( ("dropoff_datetime" - "pickup_datetime") / 1000000.0 ) AS "avg_taxi_duration"
    FROM 
        NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE 
        "pickup_datetime" BETWEEN 1451606400000000 AND 1483228800000000 AND
        "pickup_latitude" IS NOT NULL AND "pickup_longitude" IS NOT NULL AND
        "dropoff_latitude" IS NOT NULL AND "dropoff_longitude" IS NOT NULL AND
        "pickup_latitude" != 0 AND "pickup_longitude" != 0 AND
        "dropoff_latitude" != 0 AND "dropoff_longitude" != 0 AND
        ("dropoff_datetime" - "pickup_datetime") > 60000000 AND  -- Duration > 60 seconds
        ("dropoff_datetime" - "pickup_datetime") < 7200000000    -- Duration < 2 hours
    GROUP BY 
        "start_latitude", "start_longitude", "end_latitude", "end_longitude"
    HAVING
        COUNT(*) > 0
),
selected_route AS (
    SELECT
        b."start_latitude",
        b."start_longitude",
        b."end_latitude",
        b."end_longitude",
        b."trip_count",
        b."avg_bike_duration",
        t."avg_taxi_duration"
    FROM
        bike_routes b
    INNER JOIN
        taxi_routes t
    ON
        b."start_latitude" = t."start_latitude" AND
        b."start_longitude" = t."start_longitude" AND
        b."end_latitude" = t."end_latitude" AND
        b."end_longitude" = t."end_longitude"
    WHERE
        b."avg_bike_duration" < t."avg_taxi_duration"
    ORDER BY
        b."avg_bike_duration" DESC NULLS LAST
    LIMIT 1
),
start_station AS (
    SELECT
        "start_station_name"
    FROM
        NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE
        ROUND("start_station_latitude", 3) = (SELECT "start_latitude" FROM selected_route) AND
        ROUND("start_station_longitude", 3) = (SELECT "start_longitude" FROM selected_route)
    GROUP BY
        "start_station_name"
    ORDER BY
        COUNT(*) DESC NULLS LAST
    LIMIT 1
)
SELECT
    "start_station_name"
FROM
    start_station;