SELECT 
    AVG(
        DATEDIFF('second', 
            TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6), 
            TO_TIMESTAMP_NTZ(t."dropoff_datetime" / 1e6)
        ) / 60.0
    ) AS "average_trip_duration_minutes"
FROM 
    NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
JOIN 
    NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM p
    ON t."pickup_location_id" = p."zone_id"
JOIN 
    NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM d
    ON t."dropoff_location_id" = d."zone_id"
WHERE 
    TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6) BETWEEN '2016-02-01 00:00:00' AND '2016-02-07 23:59:59' AND
    DATEDIFF('second', 
        TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6), 
        TO_TIMESTAMP_NTZ(t."dropoff_datetime" / 1e6)
    ) > 0 AND
    t."passenger_count" > 3 AND
    t."trip_distance" >= 10 AND
    p."borough" = 'Brooklyn' AND
    d."borough" = 'Brooklyn';