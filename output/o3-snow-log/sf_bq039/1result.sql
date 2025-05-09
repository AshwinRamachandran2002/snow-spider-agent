WITH union_trips AS (

    /* ---------------  GREEN trips --------------- */
    SELECT
        CAST("pickup_datetime"  AS NUMBER)                                 AS pickup_ts_micro ,
        CAST("dropoff_datetime" AS NUMBER)                                 AS dropoff_ts_micro,
        CAST("passenger_count"  AS NUMBER)                                 AS passenger_cnt   ,
        CAST("trip_distance"    AS FLOAT )                                 AS trip_distance   ,
        CAST("fare_amount"      AS FLOAT )                                 AS fare_amount     ,
        CAST("tip_amount"       AS FLOAT )                                 AS tip_amount      ,
        CAST("tolls_amount"     AS FLOAT )                                 AS tolls_amount    ,
        CAST("mta_tax"          AS FLOAT )                                 AS mta_tax         ,
        CAST("total_amount"     AS FLOAT )                                 AS total_amount    ,
        "pickup_location_id"                                               AS pickup_loc_id   ,
        "dropoff_location_id"                                              AS dropoff_loc_id
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_GREEN_TRIPS_2016

    UNION ALL

    /* ---------------  YELLOW trips -------------- */
    SELECT
        CAST("pickup_datetime"  AS NUMBER)                                 AS pickup_ts_micro ,
        CAST("dropoff_datetime" AS NUMBER)                                 AS dropoff_ts_micro,
        CAST("passenger_count"  AS NUMBER)                                 AS passenger_cnt   ,
        CAST("trip_distance"    AS FLOAT )                                 AS trip_distance   ,
        CAST("fare_amount"      AS FLOAT )                                 AS fare_amount     ,
        CAST("tip_amount"       AS FLOAT )                                 AS tip_amount      ,
        CAST("tolls_amount"     AS FLOAT )                                 AS tolls_amount    ,
        CAST("mta_tax"          AS FLOAT )                                 AS mta_tax         ,
        CAST("total_amount"     AS FLOAT )                                 AS total_amount    ,
        "pickup_location_id"                                               AS pickup_loc_id   ,
        "dropoff_location_id"                                              AS dropoff_loc_id
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016
),

filtered AS (
    SELECT
        *,
        TO_TIMESTAMP(pickup_ts_micro  / 1e6)                             AS pickup_time ,
        TO_TIMESTAMP(dropoff_ts_micro / 1e6)                             AS dropoff_time,
        (dropoff_ts_micro - pickup_ts_micro) / 1e6                      AS duration_seconds
    FROM union_trips
    WHERE
          passenger_cnt  > 5
      AND trip_distance  >= 10
      AND fare_amount    >= 0
      AND tip_amount     >= 0
      AND tolls_amount   >= 0
      AND mta_tax        >= 0
      AND total_amount   >  0
      AND dropoff_ts_micro  > pickup_ts_micro                                   -- drop-after-pickup
      AND TO_TIMESTAMP(pickup_ts_micro  / 1e6) BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
      AND TO_TIMESTAMP(dropoff_ts_micro / 1e6) BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
),

enriched AS (
    SELECT
        f.*,
        z_pick."zone_name"  AS pickup_zone ,
        z_drop."zone_name"  AS dropoff_zone,
        CASE
            WHEN duration_seconds > 0
            THEN trip_distance / (duration_seconds / 3600)                -- miles per hour
        END                         AS speed_mph,
        (tip_amount / NULLIF(total_amount,0)) * 100                      AS tip_rate_pct
    FROM filtered f
    LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM z_pick
           ON z_pick."zone_id" = f.pickup_loc_id
    LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM z_drop
           ON z_drop."zone_id" = f.dropoff_loc_id
)

SELECT
    pickup_zone,
    dropoff_zone,
    duration_seconds,
    ROUND(speed_mph , 2) AS speed_mph ,
    ROUND(tip_rate_pct , 2) AS tip_rate_pct
FROM enriched
ORDER BY total_amount DESC NULLS LAST
LIMIT 10;