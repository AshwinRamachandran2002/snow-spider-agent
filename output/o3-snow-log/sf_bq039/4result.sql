WITH all_2016_trips AS (

    /* ---------------- Yellow Taxi 2016 ---------------- */
    SELECT  
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

    /* ---------------- Green  Taxi 2016 ---------------- */
    SELECT  
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

filtered AS (
    SELECT 
        *,
        TO_TIMESTAMP("pickup_datetime" / 1000000)  AS pickup_ts,
        TO_TIMESTAMP("dropoff_datetime" / 1000000) AS dropoff_ts
    FROM all_2016_trips
    WHERE
        /* date window */
        TO_TIMESTAMP("pickup_datetime"  / 1000000) BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
        AND TO_TIMESTAMP("dropoff_datetime" / 1000000) BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'

        /* data quality / business rules */
        AND "dropoff_datetime" > "pickup_datetime"
        AND "passenger_count" > 5
        AND "trip_distance"  >= 10

        /* no negative money values */
        AND "fare_amount"   >= 0
        AND "tip_amount"    >= 0
        AND "tolls_amount"  >= 0
        AND "mta_tax"       >= 0
        AND "total_amount"  >= 0
),

enriched AS (
    SELECT
        f.*,

        /* trip duration (sec) and speed (mph) */
        ( "dropoff_datetime" - "pickup_datetime") / 1000000                    AS duration_seconds,
        "trip_distance" * 3600 / NULLIF( ( "dropoff_datetime" - "pickup_datetime") / 1000000 , 0)  AS speed_mph,

        /* tip-rate % */
        ("tip_amount" / NULLIF("total_amount",0)) * 100                        AS tip_rate_pct
    FROM filtered f
)

SELECT
    pzone."zone_name"                         AS "pickup_zone",
    dzone."zone_name"                         AS "dropoff_zone",
    ROUND(e.duration_seconds)                 AS "trip_duration_seconds",
    ROUND(e.speed_mph,2)                      AS "speed_mph",
    ROUND(e.tip_rate_pct,2)                   AS "tip_rate_percent"
FROM enriched e
JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM  pzone
  ON pzone."zone_id" = e."pickup_location_id"
JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM  dzone
  ON dzone."zone_id" = e."dropoff_location_id"
ORDER BY e."total_amount" DESC NULLS LAST
LIMIT 10;