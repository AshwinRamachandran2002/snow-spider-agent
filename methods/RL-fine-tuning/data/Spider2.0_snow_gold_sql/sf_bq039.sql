SELECT
  "pz"."zone_name" AS "Pickup_Zone",
  "dz"."zone_name" AS "Dropoff_Zone",
  ("t"."dropoff_datetime" - "t"."pickup_datetime") / 1000000 AS "Trip_Duration_Seconds",
  ROUND("t"."trip_distance" / ( ( ("t"."dropoff_datetime" - "t"."pickup_datetime") / 1000000 ) / 3600 ), 4) AS "Driving_Speed_MPH",
  ROUND(CASE WHEN "t"."fare_amount" > 0 THEN ("t"."tip_amount" / "t"."fare_amount") * 100 ELSE NULL END, 4) AS "Tip_Rate_Percentage"
FROM
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" AS "t"
LEFT JOIN
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" AS "pz"
    ON "t"."pickup_location_id" = "pz"."zone_id"
LEFT JOIN
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" AS "dz"
    ON "t"."dropoff_location_id" = "dz"."zone_id"
WHERE
  TO_TIMESTAMP_LTZ("t"."pickup_datetime", 6) >= TIMESTAMP '2016-07-01 00:00:00'
  AND TO_TIMESTAMP_LTZ("t"."dropoff_datetime", 6) <= TIMESTAMP '2016-07-07 23:59:59'
  AND "t"."passenger_count" > 5
  AND "t"."trip_distance" >= 10
  AND "t"."fare_amount" >= 0
  AND "t"."tip_amount" >= 0
  AND "t"."tolls_amount" >= 0
  AND "t"."mta_tax" >= 0
  AND "t"."total_amount" >= 0
  AND "t"."dropoff_datetime" > "t"."pickup_datetime"
ORDER BY
  "t"."total_amount" DESC NULLS LAST
LIMIT 10;