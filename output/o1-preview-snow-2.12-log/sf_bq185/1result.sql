SELECT
  AVG((t."dropoff_datetime" - t."pickup_datetime") / (60 * 1e6)) AS "average_trip_duration_minutes"
FROM
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
JOIN
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" pz
  ON t."pickup_location_id" = pz."zone_id"
JOIN
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" dz
  ON t."dropoff_location_id" = dz."zone_id"
WHERE
  TO_TIMESTAMP(t."pickup_datetime" / 1e6) >= '2016-02-01'
  AND TO_TIMESTAMP(t."pickup_datetime" / 1e6) < '2016-02-08'
  AND (t."dropoff_datetime" - t."pickup_datetime") > 0
  AND t."passenger_count" > 3
  AND t."trip_distance" >= 10
  AND pz."borough" = 'Brooklyn'
  AND dz."borough" = 'Brooklyn';