SELECT
  p."zone_name" AS "pickup_zone",
  d."zone_name" AS "dropoff_zone",
  DATEDIFF('minute', TO_TIMESTAMP_LTZ(t."pickup_datetime" / 1e6), TO_TIMESTAMP_LTZ(t."dropoff_datetime" / 1e6)) AS "trip_duration_minutes",
  ROUND(t."trip_distance" / (DATEDIFF('minute', TO_TIMESTAMP_LTZ(t."pickup_datetime" / 1e6), TO_TIMESTAMP_LTZ(t."dropoff_datetime" / 1e6)) / 60), 4) AS "driving_speed_mph",
  ROUND((t."tip_amount" / t."fare_amount") * 100, 4) AS "tip_rate_percent"
FROM
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
INNER JOIN
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" p
    ON t."pickup_location_id" = p."zone_id"
INNER JOIN
  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" d
    ON t."dropoff_location_id" = d."zone_id"
WHERE
  TO_TIMESTAMP_LTZ(t."pickup_datetime" / 1e6) >= TO_TIMESTAMP('2016-07-01', 'YYYY-MM-DD')
  AND TO_TIMESTAMP_LTZ(t."pickup_datetime" / 1e6) < TO_TIMESTAMP('2016-07-08', 'YYYY-MM-DD')
  AND t."passenger_count" > 5
  AND t."trip_distance" >= 10
  AND t."fare_amount" > 0
  AND DATEDIFF('minute', TO_TIMESTAMP_LTZ(t."pickup_datetime" / 1e6), TO_TIMESTAMP_LTZ(t."dropoff_datetime" / 1e6)) > 0
  AND (t."trip_distance" / (DATEDIFF('minute', TO_TIMESTAMP_LTZ(t."pickup_datetime" / 1e6), TO_TIMESTAMP_LTZ(t."dropoff_datetime" / 1e6)) / 60)) BETWEEN 5 AND 100
ORDER BY
  t."total_amount" DESC NULLS LAST
LIMIT 10;