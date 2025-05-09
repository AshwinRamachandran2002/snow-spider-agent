WITH trips AS (
    SELECT
        t."pickup_datetime",
        t."dropoff_datetime",
        (t."dropoff_datetime" - t."pickup_datetime") / 60000000.0 AS "duration_minutes",
        t."passenger_count",
        t."trip_distance",
        t."pickup_location_id",
        t."dropoff_location_id"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TLC_YELLOW_TRIPS_2016" t
),
brooklyn_trips AS (
    SELECT
        tr."duration_minutes"
    FROM trips tr
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM" pz
        ON tr."pickup_location_id" = pz."zone_id"
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM" dz
        ON tr."dropoff_location_id" = dz."zone_id"
    WHERE
        pz."borough" = 'Brooklyn'
        AND dz."borough" = 'Brooklyn'
        AND TO_TIMESTAMP_LTZ(tr."pickup_datetime" / 1000000) >= '2016-02-01'::TIMESTAMP
        AND TO_TIMESTAMP_LTZ(tr."pickup_datetime" / 1000000) <  '2016-02-08'::TIMESTAMP
        AND tr."duration_minutes" > 0
        AND tr."passenger_count" > 3
        AND tr."trip_distance" >= 10
)
SELECT ROUND(AVG("duration_minutes"), 4) AS "avg_trip_duration_minutes"
FROM brooklyn_trips;