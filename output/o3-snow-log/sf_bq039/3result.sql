WITH trips AS (      ----------------------------------------------------  
-- gather 2016 Yellow and Green taxi trips (same columns, union all)  
----------------------------------------------------
    SELECT  'YELLOW'                                            AS taxi_type ,
            t."pickup_datetime" ,
            t."dropoff_datetime" ,
            t."pickup_location_id"                              AS pickup_id ,
            t."dropoff_location_id"                             AS dropoff_id ,
            t."passenger_count" ,
            t."trip_distance" ,
            t."fare_amount" ,
            t."tip_amount" ,
            t."tolls_amount" ,
            t."mta_tax" ,
            t."total_amount"
    FROM  NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016  t

    UNION ALL

    SELECT  'GREEN'                                             AS taxi_type ,
            t."pickup_datetime" ,
            t."dropoff_datetime" ,
            t."pickup_location_id"                              AS pickup_id ,
            t."dropoff_location_id"                             AS dropoff_id ,
            t."passenger_count" ,
            t."trip_distance" ,
            t."fare_amount" ,
            t."tip_amount" ,
            t."tolls_amount" ,
            t."mta_tax" ,
            t."total_amount"
    FROM  NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_GREEN_TRIPS_2016  t
),

cleaned AS (          -----------------------------------------------  
-- keep only trips satisfying all business rules  
------------------------------------------------
    SELECT  
        TO_TIMESTAMP("pickup_datetime"  / 1000000)              AS pickup_ts ,
        TO_TIMESTAMP("dropoff_datetime" / 1000000)              AS dropoff_ts ,
        pickup_id ,
        dropoff_id ,
        "passenger_count"                                       AS passenger_cnt ,
        "trip_distance"                                         AS trip_miles ,
        "fare_amount"       ,
        "tip_amount"        ,
        "tolls_amount"      ,
        "mta_tax"           ,
        "total_amount"      ,
        ( "dropoff_datetime" - "pickup_datetime") / 1000000     AS trip_seconds
    FROM trips
    WHERE   ---------------------------------------------------- date window
            TO_TIMESTAMP("pickup_datetime"/1000000) BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
        AND TO_TIMESTAMP("dropoff_datetime"/1000000) BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
            ---------------------------------------------------- logical trip & quality filters
        AND "dropoff_datetime"  >  "pickup_datetime"
        AND "passenger_count"   >  5
        AND "trip_distance"     >= 10
        AND "fare_amount"       >= 0
        AND "tip_amount"        >= 0
        AND "tolls_amount"      >= 0
        AND "mta_tax"           >= 0
        AND "total_amount"      >  0
)

SELECT  -----------------------------------------------------------  
        p."zone_name"                                              AS pickup_zone ,
        d."zone_name"                                              AS dropoff_zone ,
        trip_seconds                                               AS duration_seconds ,
        ROUND( trip_miles * 3600 / NULLIF(trip_seconds,0) , 2)     AS speed_mph ,
        ROUND( "tip_amount" * 100 / "total_amount"       , 2)      AS tip_rate_pct
FROM    cleaned  c
LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM   p
       ON p."zone_id" = c.pickup_id
LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM   d
       ON d."zone_id" = c.dropoff_id
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 10;