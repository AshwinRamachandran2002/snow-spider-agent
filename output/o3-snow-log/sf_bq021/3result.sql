WITH citi_2016 AS (   -- Citi Bike trips that started in 2016
    SELECT
        "start_station_id",
        "end_station_id",
        "start_station_name",
        "start_station_latitude"  AS start_lat,
        "start_station_longitude" AS start_lon,
        "end_station_latitude"    AS end_lat,
        "end_station_longitude"   AS end_lon,
        "tripduration"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE YEAR(TO_TIMESTAMP("starttime"/1000000)) = 2016
      AND "start_station_latitude"  IS NOT NULL
      AND "start_station_longitude" IS NOT NULL
      AND "end_station_latitude"    IS NOT NULL
      AND "end_station_longitude"   IS NOT NULL
),
bike_routes AS (      -- stats per Citi Bike route
    SELECT
        "start_station_id",
        "end_station_id",
        "start_station_name",
        ROUND(start_lat,3) AS s_lat_r,
        ROUND(start_lon,3) AS s_lon_r,
        ROUND(end_lat,3)   AS e_lat_r,
        ROUND(end_lon,3)   AS e_lon_r,
        COUNT(*)           AS trip_count,
        AVG("tripduration") AS avg_bike_duration
    FROM citi_2016
    GROUP BY 1,2,3,4,5,6,7
),
top20 AS (            -- 20 most–used Citi Bike routes
    SELECT *
    FROM bike_routes
    ORDER BY trip_count DESC NULLS LAST
    LIMIT 20
),
taxi_routes AS (      -- average Yellow-taxi time on same (rounded) coordinates in 2016
    SELECT
        ROUND("pickup_latitude",3)   AS s_lat_r,
        ROUND("pickup_longitude",3)  AS s_lon_r,
        ROUND("dropoff_latitude",3)  AS e_lat_r,
        ROUND("dropoff_longitude",3) AS e_lon_r,
        AVG( ("dropoff_datetime" - "pickup_datetime")/1000000 ) AS avg_taxi_duration
    FROM NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE "pickup_latitude"  IS NOT NULL
      AND "pickup_longitude" IS NOT NULL
      AND "dropoff_latitude" IS NOT NULL
      AND "dropoff_longitude" IS NOT NULL
      AND "dropoff_datetime" > "pickup_datetime"
      AND YEAR(TO_TIMESTAMP("pickup_datetime"/1000000)) = 2016
    GROUP BY 1,2,3,4
),
combined AS (         -- join top bike routes with taxi times
    SELECT t.*, tr.avg_taxi_duration
    FROM top20 t
    JOIN taxi_routes tr
      ON t.s_lat_r = tr.s_lat_r
     AND t.s_lon_r = tr.s_lon_r
     AND t.e_lat_r = tr.e_lat_r
     AND t.e_lon_r = tr.e_lon_r
)
SELECT "start_station_name"
FROM combined
WHERE avg_bike_duration < avg_taxi_duration         -- bike faster than taxi
ORDER BY avg_bike_duration DESC NULLS LAST          -- longest avg bike time among faster ones
LIMIT 1;