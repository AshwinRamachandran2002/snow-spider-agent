SELECT
    pz."zone_name" AS "Pickup_Zone",
    dz."zone_name" AS "Dropoff_Zone",
    (t."dropoff_datetime" - t."pickup_datetime") / 1000000 AS "Trip_Duration_Seconds",
    (t."trip_distance" * 3600) / ((t."dropoff_datetime" - t."pickup_datetime") / 1000000) AS "Driving_Speed_MPH",
    (t."tip_amount" / NULLIF((t."total_amount" - t."tip_amount"), 0)) * 100 AS "Tip_Rate_Percentage"
FROM "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
LEFT JOIN "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" pz
    ON t."pickup_location_id" = pz."zone_id"
LEFT JOIN "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" dz
    ON t."dropoff_location_id" = dz."zone_id"
WHERE
    t."pickup_datetime" >= 1467331200000000 AND t."pickup_datetime" < 1467936000000000
    AND t."dropoff_datetime" >= 1467331200000000 AND t."dropoff_datetime" < 1467936000000000
    AND t."passenger_count" > 5
    AND t."trip_distance" >= 10
    AND t."fare_amount" >= 0
    AND t."extra" >= 0
    AND t."mta_tax" >= 0
    AND t."tip_amount" >= 0
    AND t."tolls_amount" >= 0
    AND t."total_amount" >= 0
    AND t."dropoff_datetime" > t."pickup_datetime"
ORDER BY t."total_amount" DESC NULLS LAST
LIMIT 10;