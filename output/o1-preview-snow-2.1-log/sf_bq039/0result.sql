SELECT
    tzp."zone_name" AS "pickup_zone",
    tzd."zone_name" AS "dropoff_zone",
    ROUND( ((t."dropoff_datetime" - t."pickup_datetime") / 1e6 ) / 60, 4 ) AS "trip_duration_minutes",
    ROUND( t."trip_distance" / ( ((t."dropoff_datetime" - t."pickup_datetime") / 1e6 ) / 3600 ), 4 ) AS "driving_speed_mph",
    ROUND( (t."tip_amount" / t."fare_amount") * 100, 4 ) AS "tip_rate_percent"
FROM
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
JOIN
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" tzp
    ON t."pickup_location_id" = tzp."zone_id"
JOIN
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" tzd
    ON t."dropoff_location_id" = tzd."zone_id"
WHERE
    t."passenger_count" > 5
    AND t."trip_distance" >= 10
    AND t."fare_amount" > 0
    AND t."pickup_datetime" >= 1467331200000000
    AND t."pickup_datetime" <= 1467935999000000
    AND (t."dropoff_datetime" - t."pickup_datetime") > 0
ORDER BY
    t."total_amount" DESC NULLS LAST
LIMIT 10;