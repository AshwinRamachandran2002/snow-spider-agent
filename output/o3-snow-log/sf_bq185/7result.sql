WITH "BROOKLYN_ZONES" AS (
    SELECT "zone_id"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM
    WHERE "borough" = 'Brooklyn'
)

SELECT
    AVG( ("dropoff_datetime" - "pickup_datetime") / 60000000.0 ) AS "avg_trip_duration_minutes"
FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 AS t
JOIN "BROOKLYN_ZONES" AS pz
      ON t."pickup_location_id" = pz."zone_id"
JOIN "BROOKLYN_ZONES" AS dz
      ON t."dropoff_location_id" = dz."zone_id"
WHERE t."pickup_datetime" >= 1454284800000000       -- 2016-02-01 00:00:00 (µs)
  AND t."pickup_datetime" <  1454976000000000       -- 2016-02-08 00:00:00 (µs)
  AND t."dropoff_datetime" > t."pickup_datetime"    -- positive duration
  AND t."passenger_count" > 3                       -- more than three passengers
  AND t."trip_distance" >= 10;                      -- at least ten miles