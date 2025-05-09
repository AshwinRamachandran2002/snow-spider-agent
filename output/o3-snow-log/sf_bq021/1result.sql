WITH bike_2016 AS (           -- Citi Bike trips that started in 2016
    SELECT  "start_station_id"                                 AS start_id ,
            "end_station_id"                                   AS end_id ,
            ROUND("start_station_latitude"  , 3)               AS start_lat3 ,
            ROUND("start_station_longitude" , 3)               AS start_lon3 ,
            ROUND("end_station_latitude"    , 3)               AS end_lat3 ,
            ROUND("end_station_longitude"   , 3)               AS end_lon3 ,
            ("stoptime" - "starttime") / 1000000               AS duration_sec   -- seconds
    FROM    NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE   "start_station_id"          IS NOT NULL
        AND "end_station_id"            IS NOT NULL
        AND "start_station_latitude"    IS NOT NULL
        AND "start_station_longitude"   IS NOT NULL
        AND "end_station_latitude"      IS NOT NULL
        AND "end_station_longitude"     IS NOT NULL
        AND TO_TIMESTAMP_LTZ("starttime" / 1000000)
            BETWEEN '2016-01-01' AND '2016-12-31 23:59:59'
        AND "stoptime" > "starttime"
),
bike_routes AS (              -- top-20 Citi Bike routes by volume
    SELECT  start_id , end_id ,
            start_lat3 , start_lon3 , end_lat3 , end_lon3 ,
            AVG(duration_sec)                     AS bike_avg_dur ,
            COUNT(*)                              AS trip_cnt ,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
    FROM    bike_2016
    GROUP BY start_id , end_id ,
             start_lat3 , start_lon3 , end_lat3 , end_lon3
    QUALIFY rn <= 20
),
taxi_2016 AS (                -- Yellow-taxi trips in 2016
    SELECT  ROUND("pickup_latitude"  , 3)          AS start_lat3 ,
            ROUND("pickup_longitude" , 3)          AS start_lon3 ,
            ROUND("dropoff_latitude" , 3)          AS end_lat3 ,
            ROUND("dropoff_longitude", 3)          AS end_lon3 ,
            ("dropoff_datetime" - "pickup_datetime") / 1000000 AS duration_sec
    FROM    NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE   "pickup_latitude"   IS NOT NULL
        AND "pickup_longitude"  IS NOT NULL
        AND "dropoff_latitude"  IS NOT NULL
        AND "dropoff_longitude" IS NOT NULL
        AND "pickup_datetime"   IS NOT NULL
        AND "dropoff_datetime"  IS NOT NULL
        AND TO_TIMESTAMP_LTZ("pickup_datetime" / 1000000)
            BETWEEN '2016-01-01' AND '2016-12-31 23:59:59'
        AND "dropoff_datetime" > "pickup_datetime"
),
taxi_routes AS (              -- average taxi duration on matching 3-decimal routes
    SELECT  start_lat3 , start_lon3 , end_lat3 , end_lon3 ,
            AVG(duration_sec) AS taxi_avg_dur
    FROM    taxi_2016
    GROUP BY start_lat3 , start_lon3 , end_lat3 , end_lon3
),
faster_routes AS (            -- among top-20 bike routes, keep those faster than taxis
    SELECT  b.* , t.taxi_avg_dur
    FROM    bike_routes b
    JOIN    taxi_routes t
          ON  b.start_lat3 = t.start_lat3
          AND b.start_lon3 = t.start_lon3
          AND b.end_lat3   = t.end_lat3
          AND b.end_lon3   = t.end_lon3
    WHERE   b.bike_avg_dur < t.taxi_avg_dur
)
SELECT  s."name"  AS start_station_name
FROM    faster_routes fr
JOIN    NEW_YORK.NEW_YORK.CITIBIKE_STATIONS s
      ON s."station_id" = CAST(fr.start_id AS VARCHAR)
ORDER BY fr.bike_avg_dur DESC NULLS LAST   -- longest average bike trip among faster routes
LIMIT 1;