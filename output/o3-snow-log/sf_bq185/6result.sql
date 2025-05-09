WITH filtered AS (
    SELECT
        ( (t."dropoff_datetime" - t."pickup_datetime") / 1000000.0 ) / 60.0 AS duration_min
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM zp
      ON t."pickup_location_id" = zp."zone_id"
     AND zp."borough" = 'Brooklyn'
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM zd
      ON t."dropoff_location_id" = zd."zone_id"
     AND zd."borough" = 'Brooklyn'
    WHERE
          t."pickup_datetime" IS NOT NULL
      AND t."dropoff_datetime" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP(t."pickup_datetime" / 1000000)) BETWEEN '2016-02-01' AND '2016-02-07'
      AND (t."dropoff_datetime" - t."pickup_datetime") > 0
      AND t."passenger_count" > 3
      AND t."trip_distance" >= 10
)
SELECT
    ROUND(AVG(duration_min), 4) AS "average_trip_duration_minutes"
FROM filtered;