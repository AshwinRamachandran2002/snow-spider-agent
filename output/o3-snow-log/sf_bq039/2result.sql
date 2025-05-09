WITH all_trips AS (      -- 1. gather 2016 yellow & green taxi trips
    SELECT
        'YELLOW'                                    AS taxi_type,
        "pickup_datetime",
        "dropoff_datetime",
        "pickup_location_id",
        "dropoff_location_id",
        "passenger_count",
        "trip_distance",
        "fare_amount",
        "tip_amount",
        "tolls_amount",
        "mta_tax",
        "total_amount"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016
    
    UNION ALL
    
    SELECT
        'GREEN'                                     AS taxi_type,
        "pickup_datetime",
        "dropoff_datetime",
        "pickup_location_id",
        "dropoff_location_id",
        "passenger_count",
        "trip_distance",
        "fare_amount",
        "tip_amount",
        "tolls_amount",
        "mta_tax",
        "total_amount"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_GREEN_TRIPS_2016
),
-- 2. convert epoch-µs to timestamps
converted AS (
    SELECT
        taxi_type,
        "pickup_location_id",
        "dropoff_location_id",
        "passenger_count",
        "trip_distance",
        "fare_amount",
        "tip_amount",
        "tolls_amount",
        "mta_tax",
        "total_amount",
        TO_TIMESTAMP_NTZ("pickup_datetime"  / 1000000)  AS pickup_ts,
        TO_TIMESTAMP_NTZ("dropoff_datetime" / 1000000)  AS dropoff_ts
    FROM all_trips
),
-- 3. apply filters & derive metrics
filtered AS (
    SELECT
        taxi_type,
        "pickup_location_id",
        "dropoff_location_id",
        DATEDIFF('second', pickup_ts, dropoff_ts)                                AS trip_seconds,
        ("trip_distance" * 3600) / NULLIF(DATEDIFF('second', pickup_ts, dropoff_ts),0)   AS speed_mph,
        CASE WHEN "total_amount" > 0 THEN ("tip_amount" / "total_amount") * 100 END      AS tip_pct,
        "total_amount"
    FROM converted
    WHERE
        "passenger_count"  > 5
        AND "trip_distance" >= 10
        AND "fare_amount"  >= 0
        AND "tip_amount"   >= 0
        AND "tolls_amount" >= 0
        AND "mta_tax"      >= 0
        AND "total_amount" >= 0
        AND dropoff_ts     > pickup_ts                   -- dropoff strictly after pickup
        AND pickup_ts  BETWEEN '2016-07-01 00:00:00' AND '2016-07-07 23:59:59'
        AND dropoff_ts BETWEEN '2016-07-01 00:00:00' AND '2016-07-07 23:59:59'
)
-- 4. join to taxi-zone names & return top 10 by total fare
SELECT
    pz."zone_name"                      AS "PICKUP_ZONE",
    dz."zone_name"                      AS "DROPOFF_ZONE",
    trip_seconds                        AS "TRIP_DURATION_SECONDS",
    ROUND(speed_mph,2)                  AS "SPEED_MPH",
    ROUND(tip_pct,2)                    AS "TIP_RATE_PERCENT"
FROM filtered f
LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM pz
       ON pz."zone_id" = f."pickup_location_id"
LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM dz
       ON dz."zone_id" = f."dropoff_location_id"
ORDER BY f."total_amount" DESC NULLS LAST
LIMIT 10;