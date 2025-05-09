SELECT 
    AVG("duration_minutes") AS "avg_trip_duration_minutes"
FROM (
    SELECT 
        (("yt"."dropoff_datetime" - "yt"."pickup_datetime") / 60000000.0) AS "duration_minutes"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 AS "yt"
    INNER JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM AS "zp"
        ON "yt"."pickup_location_id" = "zp"."zone_id"
    INNER JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM AS "zd"
        ON "yt"."dropoff_location_id" = "zd"."zone_id"
    WHERE 
        TO_TIMESTAMP("yt"."pickup_datetime" / 1000000) 
            BETWEEN '2016-02-01 00:00:00' AND '2016-02-07 23:59:59'
        AND "yt"."passenger_count" > 3
        AND "yt"."trip_distance" >= 10
        AND ("yt"."dropoff_datetime" - "yt"."pickup_datetime") > 0
        AND "zp"."borough" = 'Brooklyn'
        AND "zd"."borough" = 'Brooklyn'
) ;