SELECT
    AVG( (t."dropoff_datetime" - t."pickup_datetime") / 1000000.0 / 60.0 ) AS "avg_trip_duration_minutes"
FROM
    NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 AS t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM AS p
         ON p."zone_id" = t."pickup_location_id"
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM AS d
         ON d."zone_id" = t."dropoff_location_id"
WHERE
    p."borough" = 'Brooklyn'
    AND d."borough" = 'Brooklyn'
    AND t."pickup_datetime" >= 1454284800000000        -- 2016-02-01 00:00:00 (µs)
    AND t."pickup_datetime" <  1454889600000000        -- 2016-02-08 00:00:00 (µs)
    AND (t."dropoff_datetime" - t."pickup_datetime") > 0
    AND t."passenger_count" > 3
    AND t."trip_distance"  >= 10;