WITH bike_trips_2016 AS (
    SELECT
        ROUND(s1."latitude", 3)  AS start_lat_r ,
        ROUND(s1."longitude", 3) AS start_lon_r ,
        ROUND(s2."latitude", 3)  AS end_lat_r   ,
        ROUND(s2."longitude", 3) AS end_lon_r   ,
        ct."tripduration"        AS bike_dur_sec,
        ct."start_station_name"  AS start_station_name
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS            ct
    JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS   s1 ON s1."station_id" = ct."start_station_id"::TEXT
    JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS   s2 ON s2."station_id" = ct."end_station_id"::TEXT
    WHERE YEAR(TO_TIMESTAMP(ct."starttime" / 1000000)) = 2016
      AND s1."latitude" IS NOT NULL
      AND s2."latitude" IS NOT NULL
),
bike_routes AS (
    SELECT
        start_lat_r,
        start_lon_r,
        end_lat_r,
        end_lon_r,
        COUNT(*)                         AS bike_trip_cnt,
        AVG(bike_dur_sec)                AS avg_bike_dur,
        MAX(start_station_name)          AS start_station_name   -- representative name
    FROM bike_trips_2016
    GROUP BY start_lat_r, start_lon_r, end_lat_r, end_lon_r
),
top20_bike_routes AS (
    SELECT *
    FROM bike_routes
    ORDER BY bike_trip_cnt DESC NULLS LAST
    LIMIT 20
),
taxi_trips_2016 AS (
    SELECT
        ROUND("pickup_latitude",  3) AS start_lat_r,
        ROUND("pickup_longitude", 3) AS start_lon_r,
        ROUND("dropoff_latitude", 3) AS end_lat_r,
        ROUND("dropoff_longitude",3) AS end_lon_r,
        ("dropoff_datetime" - "pickup_datetime") / 1000000.0 AS taxi_dur_sec
    FROM NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE "pickup_latitude"  IS NOT NULL
      AND "dropoff_latitude" IS NOT NULL
      AND "pickup_datetime"  IS NOT NULL
      AND "dropoff_datetime" IS NOT NULL
      AND YEAR(TO_TIMESTAMP("pickup_datetime" / 1000000)) = 2016
      AND ("dropoff_datetime" - "pickup_datetime") > 0
),
taxi_routes AS (
    SELECT
        start_lat_r,
        start_lon_r,
        end_lat_r,
        end_lon_r,
        AVG(taxi_dur_sec) AS avg_taxi_dur
    FROM taxi_trips_2016
    GROUP BY start_lat_r, start_lon_r, end_lat_r, end_lon_r
),
compare_routes AS (
    SELECT
        b.start_station_name,
        b.avg_bike_dur,
        t.avg_taxi_dur
    FROM top20_bike_routes b
    JOIN taxi_routes     t
      ON b.start_lat_r = t.start_lat_r
     AND b.start_lon_r = t.start_lon_r
     AND b.end_lat_r   = t.end_lat_r
     AND b.end_lon_r   = t.end_lon_r
    WHERE b.avg_bike_dur < t.avg_taxi_dur         -- bike faster than taxi
),
winner AS (
    SELECT *
    FROM compare_routes
    ORDER BY avg_bike_dur DESC NULLS LAST         -- longest (yet still faster) bike route
    LIMIT 1
)
SELECT start_station_name
FROM winner;