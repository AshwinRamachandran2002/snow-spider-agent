WITH union_trips AS (   /* combine 2016 green + yellow taxi trips */
    SELECT
        TO_TIMESTAMP_LTZ( FLOOR("pickup_datetime"  / 1000000) ) AS pickup_ts,
        TO_TIMESTAMP_LTZ( FLOOR("dropoff_datetime" / 1000000) ) AS dropoff_ts,
        CAST("passenger_count"  AS FLOAT)  AS passenger_cnt,
        CAST("trip_distance"    AS FLOAT)  AS trip_miles,
        CAST("fare_amount"      AS FLOAT)  AS fare_amt,
        CAST("tip_amount"       AS FLOAT)  AS tip_amt,
        CAST("tolls_amount"     AS FLOAT)  AS tolls_amt,
        CAST("mta_tax"          AS FLOAT)  AS mta_tax_amt,
        CAST("total_amount"     AS FLOAT)  AS total_amt,
        "pickup_location_id"    AS pu_zone_id,
        "dropoff_location_id"   AS do_zone_id
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_GREEN_TRIPS_2016

    UNION ALL

    SELECT
        TO_TIMESTAMP_LTZ( FLOOR("pickup_datetime"  / 1000000) ) AS pickup_ts,
        TO_TIMESTAMP_LTZ( FLOOR("dropoff_datetime" / 1000000) ) AS dropoff_ts,
        CAST("passenger_count"  AS FLOAT)  AS passenger_cnt,
        CAST("trip_distance"    AS FLOAT)  AS trip_miles,
        CAST("fare_amount"      AS FLOAT)  AS fare_amt,
        CAST("tip_amount"       AS FLOAT)  AS tip_amt,
        CAST("tolls_amount"     AS FLOAT)  AS tolls_amt,
        CAST("mta_tax"          AS FLOAT)  AS mta_tax_amt,
        CAST("total_amount"     AS FLOAT)  AS total_amt,
        "pickup_location_id"    AS pu_zone_id,
        "dropoff_location_id"   AS do_zone_id
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016
),

filtered AS (          /* apply requested filters */
    SELECT *
    FROM union_trips
    WHERE
          pickup_ts  BETWEEN '2016-07-01 00:00:00' AND '2016-07-07 23:59:59'
      AND dropoff_ts BETWEEN '2016-07-01 00:00:00' AND '2016-07-07 23:59:59'
      AND dropoff_ts  >  pickup_ts
      AND passenger_cnt  > 5
      AND trip_miles    >= 10
      AND fare_amt      >= 0
      AND tip_amt       >= 0
      AND tolls_amt     >= 0
      AND mta_tax_amt   >= 0
      AND total_amt     >= 0
),

joined_zones AS (      /* attach readable zone names */
    SELECT
        pz."zone_name"                                    AS pickup_zone,
        dz."zone_name"                                    AS dropoff_zone,
        trip_miles,
        passenger_cnt,
        fare_amt,
        tip_amt,
        tolls_amt,
        mta_tax_amt,
        total_amt,
        pickup_ts,
        dropoff_ts,
        DATEDIFF('second', pickup_ts, dropoff_ts)         AS duration_secs
    FROM filtered f
    LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM  pz
           ON pz."zone_id" = f.pu_zone_id
    LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM  dz
           ON dz."zone_id" = f.do_zone_id
)

SELECT
    pickup_zone,
    dropoff_zone,
    duration_secs,
    ROUND( trip_miles * 3600 / NULLIF(duration_secs,0), 2 )                 AS speed_mph,
    ROUND( CASE WHEN total_amt > 0 THEN tip_amt * 100 / total_amt END , 2 ) AS tip_rate_pct
FROM joined_zones
ORDER BY total_amt DESC NULLS LAST
LIMIT 10;