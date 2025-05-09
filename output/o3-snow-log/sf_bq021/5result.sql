WITH bike_2016 AS (
    SELECT
        ROUND("start_station_latitude",3)    AS start_lat,
        ROUND("start_station_longitude",3)   AS start_lon,
        ROUND("end_station_latitude",3)      AS end_lat,
        ROUND("end_station_longitude",3)     AS end_lon,
        MIN("start_station_name")            AS start_station_name,   -- name identical within a pair
        COUNT(*)                             AS trip_cnt,
        AVG("tripduration")/60.0             AS avg_bike_min
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "starttime" BETWEEN 1451606400000000 AND 1483228800000000   -- year 2016 (µs)
      AND "start_station_latitude" IS NOT NULL
      AND "end_station_latitude"   IS NOT NULL
    GROUP BY
        ROUND("start_station_latitude",3),
        ROUND("start_station_longitude",3),
        ROUND("end_station_latitude",3),
        ROUND("end_station_longitude",3)
),
top20 AS (     -- 20 most–ridden Citi-Bike routes in 2016
    SELECT *
    FROM bike_2016
    ORDER BY trip_cnt DESC NULLS LAST
    LIMIT 20
),
taxi_trips_2016 AS (
    SELECT
        ROUND("pickup_latitude",3)   AS start_lat,
        ROUND("pickup_longitude",3)  AS start_lon,
        ROUND("dropoff_latitude",3)  AS end_lat,
        ROUND("dropoff_longitude",3) AS end_lon,
        ( "dropoff_datetime" - "pickup_datetime")/1000000.0/60.0  AS trip_min
    FROM NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE "pickup_datetime" BETWEEN 1451606400000000 AND 1483228800000000   -- 2016
      AND "pickup_latitude"  IS NOT NULL
      AND "pickup_longitude" IS NOT NULL
      AND "dropoff_latitude" IS NOT NULL
      AND "dropoff_longitude" IS NOT NULL
      AND "dropoff_datetime" > "pickup_datetime"
),
taxi_routes AS (   -- average taxi time on identical rounded routes
    SELECT
        start_lat, start_lon, end_lat, end_lon,
        AVG(trip_min) AS avg_taxi_min
    FROM taxi_trips_2016
    GROUP BY start_lat, start_lon, end_lat, end_lon
),
bike_vs_taxi AS (
    SELECT
        b.start_station_name,
        b.avg_bike_min,
        t.avg_taxi_min
    FROM top20 b
    JOIN taxi_routes t
      ON  b.start_lat = t.start_lat
     AND  b.start_lon = t.start_lon
     AND  b.end_lat   = t.end_lat
     AND  b.end_lon   = t.end_lon
    WHERE b.avg_bike_min < t.avg_taxi_min      -- routes where bikes are faster
)
SELECT
    start_station_name
FROM bike_vs_taxi
ORDER BY avg_bike_min DESC NULLS LAST   -- longest average bike trip among the “faster” routes
LIMIT 1;