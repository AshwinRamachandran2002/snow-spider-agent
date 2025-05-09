SELECT 
    ROUND( AVG( (t."dropoff_datetime" - t."pickup_datetime") / 1000000.0 / 60.0 ), 4 ) AS "average_trip_duration_minutes"
FROM
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
JOIN 
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" z
ON
    t."pickup_location_id" = z."zone_id"
WHERE
    z."borough" = 'Brooklyn'
    AND t."passenger_count" > 3
    AND t."trip_distance" >= 10
    AND t."pickup_datetime" >= 1454284800000000
    AND t."pickup_datetime" < 1454889600000000
    AND (t."dropoff_datetime" - t."pickup_datetime") > 0