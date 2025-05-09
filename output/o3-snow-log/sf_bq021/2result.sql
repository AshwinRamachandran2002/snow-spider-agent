WITH bike_2016 AS (
    SELECT
        ROUND("start_station_latitude", 3)  AS s_lat_r,
        ROUND("start_station_longitude", 3) AS s_lon_r,
        ROUND("end_station_latitude", 3)    AS e_lat_r,
        ROUND("end_station_longitude", 3)   AS e_lon_r,
        "start_station_name",
        "end_station_name",
        "tripduration"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE YEAR(TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2016
      AND "start_station_latitude" IS NOT NULL
      AND "end_station_latitude"   IS NOT NULL
),
top20_bike AS (
    SELECT
        s_lat_r, s_lon_r,
        e_lat_r, e_lon_r,
        "start_station_name",
        "end_station_name",
        COUNT(*)              AS bike_trips,
        AVG("tripduration")   AS avg_bike_sec
    FROM bike_2016
    GROUP BY s_lat_r, s_lon_r, e_lat_r, e_lon_r,
             "start_station_name", "end_station_name"
    ORDER BY bike_trips DESC NULLS LAST
    LIMIT 20
),
taxi_2016 AS (
    SELECT
        ROUND("pickup_latitude",  3) AS s_lat_r,
        ROUND("pickup_longitude", 3) AS s_lon_r,
        ROUND("dropoff_latitude", 3) AS e_lat_r,
        ROUND("dropoff_longitude",3) AS e_lon_r,
        ("dropoff_datetime" - "pickup_datetime") / 1000000 AS duration_sec
    FROM NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE YEAR(TO_TIMESTAMP_NTZ("pickup_datetime" / 1000000)) = 2016
      AND "pickup_latitude"  IS NOT NULL
      AND "dropoff_latitude" IS NOT NULL
      AND "pickup_datetime"  IS NOT NULL
      AND "dropoff_datetime" IS NOT NULL
      AND "dropoff_datetime" > "pickup_datetime"
),
taxi_avg AS (
    SELECT
        s_lat_r, s_lon_r,
        e_lat_r, e_lon_r,
        AVG(duration_sec) AS avg_taxi_sec
    FROM taxi_2016
    GROUP BY s_lat_r, s_lon_r, e_lat_r, e_lon_r
),
faster_routes AS (
    SELECT
        b."start_station_name"  AS start_station_name,
        b.avg_bike_sec,
        t.avg_taxi_sec
    FROM top20_bike b
    JOIN taxi_avg t
      ON b.s_lat_r = t.s_lat_r
     AND b.s_lon_r = t.s_lon_r
     AND b.e_lat_r = t.e_lat_r
     AND b.e_lon_r = t.e_lon_r
    WHERE b.avg_bike_sec < t.avg_taxi_sec
)
SELECT start_station_name
FROM   faster_routes
ORDER  BY avg_bike_sec DESC NULLS LAST
LIMIT  1;