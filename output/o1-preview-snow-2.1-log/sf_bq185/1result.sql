SELECT AVG( (t."dropoff_datetime" - t."pickup_datetime") / 1000000.0 / 60 ) AS "average_trip_duration_minutes"
FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM zp ON t."pickup_location_id" = zp."zone_id"
JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM zd ON t."dropoff_location_id" = zd."zone_id"
WHERE
  t."pickup_datetime" BETWEEN 1454284800000000 AND 1454889599000000
  AND t."passenger_count" > 3
  AND t."trip_distance" >= 10
  AND (zp."borough" = 'Brooklyn' OR zd."borough" = 'Brooklyn')
  AND t."dropoff_datetime" > t."pickup_datetime";