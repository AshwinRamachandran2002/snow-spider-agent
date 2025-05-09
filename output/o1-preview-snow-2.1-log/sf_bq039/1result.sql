SELECT
    pz."zone_name" AS "pickup_zone",
    dz."zone_name" AS "dropoff_zone",
    ROUND(((t."dropoff_datetime" - t."pickup_datetime") / 1000000) / 60, 4) AS "trip_duration_minutes",
    ROUND(t."trip_distance" / (((t."dropoff_datetime" - t."pickup_datetime") / 1000000) / 3600), 4) AS "driving_speed_mph",
    ROUND((t."tip_amount" / t."fare_amount") * 100, 4) AS "tip_rate_percent"
FROM "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
JOIN "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" pz
    ON t."pickup_location_id" = pz."zone_id"
JOIN "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" dz
    ON t."dropoff_location_id" = dz."zone_id"
WHERE t."passenger_count" > 5
    AND t."trip_distance" >= 10
    AND t."fare_amount" > 0
    AND TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1000000) BETWEEN '2016-07-01 00:00:00' AND '2016-07-07 23:59:59'
    AND (t."dropoff_datetime" - t."pickup_datetime") > 0
ORDER BY t."fare_amount" DESC NULLS LAST
LIMIT 10;