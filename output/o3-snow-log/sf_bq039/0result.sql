WITH trips_union AS (   -- combine 2016 yellow & green taxi trips
    SELECT
        'YELLOW'                                                    AS "taxi_type",
        "pickup_datetime"                                           AS "pickup_ts",
        "dropoff_datetime"                                          AS "dropoff_ts",
        "pickup_location_id"                                        AS "pickup_loc",
        "dropoff_location_id"                                       AS "drop_loc",
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
        'GREEN'                                                     AS "taxi_type",
        "pickup_datetime"                                           AS "pickup_ts",
        "dropoff_datetime"                                          AS "dropoff_ts",
        "pickup_location_id"                                        AS "pickup_loc",
        "dropoff_location_id"                                       AS "drop_loc",
        "passenger_count",
        "trip_distance",
        "fare_amount",
        "tip_amount",
        "tolls_amount",
        "mta_tax",
        "total_amount"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_GREEN_TRIPS_2016
),

filtered AS (   -- apply all required filters
    SELECT *
    FROM trips_union
    WHERE  "passenger_count" > 5
      AND  "trip_distance"  >= 10
      AND  "fare_amount"    >= 0
      AND  "tip_amount"     >= 0
      AND  "tolls_amount"   >= 0
      AND  "mta_tax"        >= 0
      AND  "total_amount"   >  0      -- avoid divide-by-zero, ensure non-negative
      AND  "dropoff_ts"  >   "pickup_ts"
      AND  TO_TIMESTAMP("pickup_ts" / 1000000) BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
      AND  TO_TIMESTAMP("dropoff_ts" / 1000000) BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
),

calc AS (   -- compute duration, speed, tip %
    SELECT
        f.*,
        TO_TIMESTAMP("pickup_ts" / 1000000)               AS "pickup_time",
        TO_TIMESTAMP("dropoff_ts"/ 1000000)               AS "dropoff_time",
        ("dropoff_ts" - "pickup_ts")/1000000              AS "duration_sec",
        ("trip_distance" * 3600) /                NULLIF( ("dropoff_ts" - "pickup_ts")/1000000 ,0)  AS "speed_mph",
        ("tip_amount" / "total_amount") * 100             AS "tip_pct"
    FROM filtered f
),

with_zones AS (   -- attach zone names
    SELECT
        p."zone_name"                                     AS "pickup_zone",
        d."zone_name"                                     AS "dropoff_zone",
        c."duration_sec",
        ROUND(c."speed_mph", 2)                           AS "speed_mph",
        ROUND(c."tip_pct",   2)                           AS "tip_pct",
        c."total_amount"
    FROM calc c
    LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM p
           ON c."pickup_loc" = p."zone_id"
    LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM d
           ON c."drop_loc"   = d."zone_id"
)

SELECT
    "pickup_zone",
    "dropoff_zone",
    "duration_sec",
    "speed_mph",
    "tip_pct"
FROM with_zones
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 10;