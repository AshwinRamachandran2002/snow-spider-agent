WITH ALL_TRIPS AS (          -- combine 2016 Green & Yellow trip tables
    SELECT  CAST("pickup_datetime"  AS NUMBER)       AS pickup_micro ,
            CAST("dropoff_datetime" AS NUMBER)       AS dropoff_micro,
            CAST("passenger_count"  AS FLOAT )       AS passenger_cnt ,
            CAST("trip_distance"    AS FLOAT )       AS trip_miles   ,
            CAST("tip_amount"       AS FLOAT )       AS tip_amt      ,
            CAST("tolls_amount"     AS FLOAT )       AS tolls_amt    ,
            CAST("mta_tax"          AS FLOAT )       AS mta_tax_amt  ,
            CAST("fare_amount"      AS FLOAT )       AS fare_amt     ,
            CAST("total_amount"     AS FLOAT )       AS total_amt    ,
            "pickup_location_id"                        AS pu_zone_id,
            "dropoff_location_id"                       AS do_zone_id
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_GREEN_TRIPS_2016
    
    UNION ALL
    
    SELECT  CAST("pickup_datetime"  AS NUMBER) ,
            CAST("dropoff_datetime" AS NUMBER) ,
            CAST("passenger_count"  AS FLOAT ) ,
            CAST("trip_distance"    AS FLOAT ) ,
            CAST("tip_amount"       AS FLOAT ) ,
            CAST("tolls_amount"     AS FLOAT ) ,
            CAST("mta_tax"          AS FLOAT ) ,
            CAST("fare_amount"      AS FLOAT ) ,
            CAST("total_amount"     AS FLOAT ) ,
            "pickup_location_id" ,
            "dropoff_location_id"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016
),

FILTERED AS (                -- apply all requested filters
    SELECT  *,
            TO_TIMESTAMP(pickup_micro / 1e6)  AS pu_ts,
            TO_TIMESTAMP(dropoff_micro/ 1e6)  AS do_ts
    FROM    ALL_TRIPS
    WHERE   passenger_cnt  > 5
      AND   trip_miles     >= 10
      AND   dropoff_micro  > pickup_micro              -- drop-off after pick-up
      AND   tip_amt        >= 0
      AND   tolls_amt      >= 0
      AND   mta_tax_amt    >= 0
      AND   fare_amt       >= 0
      AND   total_amt      >= 0
      -- both pick-up and drop-off between 1 Jul 2016 and 7 Jul 2016 inclusive
      AND   DATE(pu_ts) BETWEEN '2016-07-01' AND '2016-07-07'
      AND   DATE(do_ts) BETWEEN '2016-07-01' AND '2016-07-07'
),

ENRICHED AS (                -- compute duration, speed, tip %
    SELECT  pu_zone_id,
            do_zone_id,
            DATEDIFF('second', pu_ts, do_ts)                    AS duration_sec,
            trip_miles * 3600 / NULLIF(DATEDIFF('second', pu_ts, do_ts),0)
                                                                AS speed_mph,
            tip_amt * 100 / NULLIF(total_amt,0)                 AS tip_pct,
            total_amt
    FROM    FILTERED
)

SELECT  COALESCE(pu."zone_name", 'Unknown') AS "PICKUP_ZONE",
        COALESCE(do."zone_name", 'Unknown') AS "DROPOFF_ZONE",
        duration_sec                        AS "TRIP_DURATION_SEC",
        ROUND(speed_mph , 2)                AS "DRIVING_SPEED_MPH",
        ROUND(tip_pct  , 2)                 AS "TIP_RATE_PERCENT"
FROM    ENRICHED   t
LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM pu
       ON pu."zone_id" = t.pu_zone_id
LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM do
       ON do."zone_id" = t.do_zone_id
ORDER BY total_amt DESC NULLS LAST
LIMIT 10;