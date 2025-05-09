WITH trips AS (

    /* -----------------------------------------------------------
       2016 Green and Yellow taxi trips (select only needed columns)
    ----------------------------------------------------------- */
    SELECT
        'GREEN'                           AS "taxi_type",
        "pickup_datetime",
        "dropoff_datetime",
        "passenger_count",
        "trip_distance",
        "fare_amount",
        "tip_amount",
        "tolls_amount",
        "mta_tax",
        "total_amount",
        "pickup_location_id",
        "dropoff_location_id"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_GREEN_TRIPS_2016

    UNION ALL

    SELECT
        'YELLOW'                          AS "taxi_type",
        "pickup_datetime",
        "dropoff_datetime",
        "passenger_count",
        "trip_distance",
        "fare_amount",
        "tip_amount",
        "tolls_amount",
        "mta_tax",
        "total_amount",
        "pickup_location_id",
        "dropoff_location_id"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016
),

/* ---------------------------------------------------------------
   Filter trips by date range, quality criteria, and basic sanity
---------------------------------------------------------------- */
trips_filtered AS (
    SELECT
        *,
        /* raw micro-second timestamps → Snowflake NTZ timestamps */
        TO_TIMESTAMP_NTZ("pickup_datetime"  / 1000000)  AS "pickup_ts",
        TO_TIMESTAMP_NTZ("dropoff_datetime" / 1000000)  AS "dropoff_ts"
    FROM trips
    WHERE
          /* Date window: 1 Jul 2016 00:00:00 – 7 Jul 2016 23:59:59 */
          TO_TIMESTAMP_NTZ("pickup_datetime"  / 1000000) BETWEEN '2016-07-01 00:00:00' AND '2016-07-07 23:59:59'
      AND TO_TIMESTAMP_NTZ("dropoff_datetime" / 1000000) BETWEEN '2016-07-01 00:00:00' AND '2016-07-07 23:59:59'

          /* Passenger & distance constraints */
      AND "passenger_count" > 5
      AND "trip_distance"  >= 10

          /* Chronology check */
      AND "dropoff_datetime" > "pickup_datetime"

          /* Disallow negative money values */
      AND "fare_amount"   >= 0
      AND "tip_amount"    >= 0
      AND "tolls_amount"  >= 0
      AND "mta_tax"       >= 0
      AND "total_amount"  >= 0
),

/* ---------------------------------------------------------------
   Enrich with zone names & compute derived metrics
---------------------------------------------------------------- */
enriched AS (
    SELECT
        p_zone."zone_name"                         AS "pickup_zone",
        d_zone."zone_name"                         AS "dropoff_zone",
        DATEDIFF('second', "pickup_ts", "dropoff_ts") AS "trip_duration_seconds",

        /* Speed (mph) = distance ÷ hours */
        CASE 
            WHEN DATEDIFF('second', "pickup_ts", "dropoff_ts") > 0
            THEN ("trip_distance" * 3600.0) 
                 / DATEDIFF('second', "pickup_ts", "dropoff_ts")
        END                                         AS "speed_mph",

        /* Tip rate (% of total fare) */
        CASE 
            WHEN "total_amount" > 0
            THEN ("tip_amount" / "total_amount") * 100
        END                                         AS "tip_rate_pct",

        "total_amount"
    FROM trips_filtered  tf
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM  p_zone
          ON p_zone."zone_id" = tf."pickup_location_id"
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM  d_zone
          ON d_zone."zone_id" = tf."dropoff_location_id"
)

/* ---------------------------------------------------------------
   Top 10 most expensive qualifying rides
---------------------------------------------------------------- */
SELECT
    "pickup_zone",
    "dropoff_zone",
    "trip_duration_seconds",
    ROUND("speed_mph",     2)  AS "speed_mph",
    ROUND("tip_rate_pct",  2)  AS "tip_rate_pct"
FROM enriched
ORDER BY "total_amount" DESC NULLS LAST
LIMIT 10;