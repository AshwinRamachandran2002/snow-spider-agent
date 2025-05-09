/*  Start-station name of the Citi Bike route (among the 20 most–frequent
    2016 routes) that is FASTER than yellow taxis running over the same
    rounded start-/end-coordinate pair and, among those faster routes,
    has the LONGEST average bike duration.                                        */

WITH station_coords AS (                          -- station locations (3-dec. precision)
    SELECT  "name"                        AS station_name ,
            ROUND("latitude" , 3)         AS lat3 ,
            ROUND("longitude", 3)         AS lon3
    FROM    NEW_YORK.NEW_YORK.CITIBIKE_STATIONS
    GROUP  BY "name" , ROUND("latitude",3) , ROUND("longitude",3)
),

/* -------------------------------  C I T I  B I K E  ( 2 0 1 6 )  ------------------------------ */
bike_trips_2016 AS (
    SELECT  t."start_station_name"                AS start_name ,
            t."end_station_name"                  AS end_name   ,
            s1.lat3                               AS start_lat3 ,
            s1.lon3                               AS start_lon3 ,
            s2.lat3                               AS end_lat3   ,
            s2.lon3                               AS end_lon3   ,
            t."tripduration"                      AS bike_sec
    FROM    NEW_YORK.NEW_YORK.CITIBIKE_TRIPS t
            JOIN station_coords s1 ON s1.station_name = t."start_station_name"
            JOIN station_coords s2 ON s2.station_name = t."end_station_name"
    WHERE   YEAR( TO_TIMESTAMP( t."starttime" / 1e6 ) ) = 2016
),

bike_route_stats AS (                            -- statistics per bike route
    SELECT  start_name , end_name ,
            start_lat3 , start_lon3 , end_lat3 , end_lon3 ,
            COUNT(*)                       AS bike_trip_cnt ,
            AVG(bike_sec)                  AS avg_bike_sec ,
            /* straight-line (haversine) distance in miles */
            ( 2 * 6371 * ASIN( SQRT(
                  POWER( SIN( RADIANS(end_lat3  - start_lat3 ) / 2) , 2) +
                  COS( RADIANS(start_lat3) ) * COS( RADIANS(end_lat3) ) *
                  POWER( SIN( RADIANS(end_lon3 - start_lon3) / 2) , 2)
              ))) * 0.621371              AS dist_miles
    FROM    bike_trips_2016
    GROUP  BY start_name , end_name ,
              start_lat3 , start_lon3 , end_lat3 , end_lon3
),

top20_bike AS (                                 -- 20 most-frequent 2016 bike routes
    SELECT *
    FROM   bike_route_stats
    ORDER  BY bike_trip_cnt DESC NULLS LAST
    LIMIT  20
),

bike_speed AS (                                 -- avg bike speed (mph)
    SELECT *,
           dist_miles / (avg_bike_sec / 3600.0) AS bike_mph
    FROM   top20_bike
),

/* -----------------------------  Y E L L O W  T A X I  ( 2 0 1 6 ) ----------------------------- */
taxi_trips_2016 AS (                            -- usable taxi trips with same rounding
    SELECT  ROUND("pickup_latitude" ,3)  AS start_lat3 ,
            ROUND("pickup_longitude",3)  AS start_lon3 ,
            ROUND("dropoff_latitude",3)  AS end_lat3   ,
            ROUND("dropoff_longitude",3) AS end_lon3   ,
            (("dropoff_datetime" - "pickup_datetime") / 1e6)  AS taxi_sec
    FROM    NEW_YORK.NEW_YORK.TLC_YELLOW_TRIPS_2016
    WHERE   "pickup_latitude"  IS NOT NULL
      AND   "pickup_longitude" IS NOT NULL
      AND   "dropoff_latitude" IS NOT NULL
      AND   "dropoff_longitude" IS NOT NULL
      AND   (("dropoff_datetime" - "pickup_datetime") > 0)
),

taxi_route_stats AS (                           -- average taxi duration & speed per route
    SELECT  start_lat3 , start_lon3 , end_lat3 , end_lon3 ,
            AVG(taxi_sec)                          AS avg_taxi_sec
    FROM    taxi_trips_2016
    GROUP  BY start_lat3 , start_lon3 , end_lat3 , end_lon3
),

taxi_speed AS (                                 -- attach straight-line distance for mph
    SELECT  tr.* ,
            br.dist_miles ,
            br.dist_miles / (tr.avg_taxi_sec / 3600.0) AS taxi_mph
    FROM    taxi_route_stats tr
            JOIN bike_route_stats br      -- same rounded coordinates guarantee match
              ON  tr.start_lat3 = br.start_lat3
             AND tr.start_lon3 = br.start_lon3
             AND tr.end_lat3   = br.end_lat3
             AND tr.end_lon3   = br.end_lon3
),

/* -----------------------------   C O M P A R I S O N  ----------------------------------------- */
faster_than_taxi AS (                          -- top-20 bike routes faster than taxis
    SELECT  b.*
    FROM    bike_speed b
            JOIN taxi_speed t
              ON  b.start_lat3 = t.start_lat3
             AND b.start_lon3 = t.start_lon3
             AND b.end_lat3   = t.end_lat3
             AND b.end_lon3   = t.end_lon3
    WHERE   b.bike_mph > t.taxi_mph
)

/* ---------------------------------   F I N A L   --------------------------------------------- */
SELECT  start_name
FROM    faster_than_taxi
ORDER  BY avg_bike_sec DESC NULLS LAST          -- longest average bike duration
LIMIT 1;