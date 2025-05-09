WITH bike_2016 AS (         -- Citi Bike trips that started in calendar-year 2016
    SELECT *
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "starttime" >= 1451606400000000     -- 2016-01-01 00:00:00
      AND "starttime" <  1483228800000000     -- 2017-01-01 00:00:00
      AND "start_station_latitude"  IS NOT NULL
      AND "end_station_latitude"    IS NOT NULL
),
bike_routes AS (            -- build each bike “route” using coordinates rounded to 3-decimals
    SELECT
        ROUND("start_station_latitude",  3) AS start_lat3,
        ROUND("start_station_longitude", 3) AS start_lon3,
        ROUND("end_station_latitude",    3) AS end_lat3,
        ROUND("end_station_longitude",   3) AS end_lon3,
        "start_station_name",
        COUNT(*)                        AS rides,
        AVG("tripduration")             AS avg_bike_dur              -- seconds
    FROM bike_2016
    GROUP BY 1,2,3,4,5
),
top20_bike AS (              -- take the 20 most–ridden bike routes
    SELECT *
    FROM bike_routes
    ORDER BY rides DESC NULLS LAST
    LIMIT 20
),
taxi_2016 AS (               -- yellow-taxi trips during 2016 with valid coords & positive duration
    SELECT *
    FROM NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE "pickup_datetime"  >= 1451606400000000
      AND "pickup_datetime"  <  1483228800000000
      AND "pickup_latitude"  IS NOT NULL
      AND "dropoff_latitude" IS NOT NULL
      AND "dropoff_datetime" IS NOT NULL
      AND "dropoff_datetime" >  "pickup_datetime"
),
taxi_routes AS (             -- aggregate taxi routes with the same 3-decimal coordinate pairs
    SELECT
        ROUND("pickup_latitude",  3) AS start_lat3,
        ROUND("pickup_longitude", 3) AS start_lon3,
        ROUND("dropoff_latitude", 3) AS end_lat3,
        ROUND("dropoff_longitude",3) AS end_lon3,
        AVG( ("dropoff_datetime" - "pickup_datetime") / 1000000.0 ) AS avg_taxi_dur -- seconds
    FROM taxi_2016
    GROUP BY 1,2,3,4
),
compare AS (                 -- join the bike top-20 routes with their matching taxi routes
    SELECT
        b.*,
        t.avg_taxi_dur
    FROM top20_bike b
    JOIN taxi_routes t
      ON b.start_lat3 = t.start_lat3
     AND b.start_lon3 = t.start_lon3
     AND b.end_lat3   = t.end_lat3
     AND b.end_lon3   = t.end_lon3
    WHERE b.avg_bike_dur < t.avg_taxi_dur     -- bike route is faster than taxi
)
-- among the faster-than-taxi routes, pick the one whose (still-fast) bike duration is longest
SELECT "start_station_name"
FROM compare
ORDER BY avg_bike_dur DESC NULLS LAST
LIMIT 1;