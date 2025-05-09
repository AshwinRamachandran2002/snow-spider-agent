WITH base AS (   -------------------------------------------------------------  
/* 1.  keep only valid yellow-taxi trips picked-up AND dropped-off                */
/*    between 1-Jan-2016 and 7-Jan-2016 (inclusive)                              */
/*    – drop-off after pick-up                                                   */
/*    – passenger_cnt > 0                                                        */
/*    – distance, money fields non-negative                                      */
    SELECT
        t."pickup_datetime",
        t."dropoff_datetime",
        t."passenger_count",
        t."trip_distance",
        COALESCE(t."tip_amount",   0) AS tip_amount,
        COALESCE(t."tolls_amount", 0) AS tolls_amount,
        COALESCE(t."mta_tax",      0) AS mta_tax,
        COALESCE(t."fare_amount",  0) AS fare_amount,
        COALESCE(t."total_amount", 0) AS total_amount,
        t."pickup_location_id"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TLC_YELLOW_TRIPS_2016"  t
    WHERE  t."passenger_count"            >  0
      AND  t."trip_distance"              >= 0
      AND  COALESCE(t."tip_amount",   0)  >= 0
      AND  COALESCE(t."tolls_amount", 0)  >= 0
      AND  COALESCE(t."mta_tax",      0)  >= 0
      AND  COALESCE(t."fare_amount",  0)  >= 0
      AND  COALESCE(t."total_amount",0)   >= 0
      -- keep trips whose pick-up & drop-off happen 2016-01-01 … 2016-01-07
      AND  DATE(TO_TIMESTAMP_LTZ(t."pickup_datetime" / 1000000))
           BETWEEN '2016-01-01' AND '2016-01-07'
      AND  DATE(TO_TIMESTAMP_LTZ(t."dropoff_datetime" / 1000000))
           BETWEEN '2016-01-01' AND '2016-01-07'
      AND  t."dropoff_datetime"           >  t."pickup_datetime"
),   
enriched AS (   --------------------------------------------------------------  
/* 2. attach pick-up borough and compute trip tip rate                           */
    SELECT
        z."borough",
        CASE WHEN b.total_amount = 0
             THEN 0
             ELSE (b.tip_amount * 100.0) / b.total_amount
        END               AS tip_rate
    FROM base b
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM"  z
          ON z."zone_id" = b."pickup_location_id"
    WHERE z."borough" IS NOT NULL
)  
/* 3. percentage of NO-TIP trips within each pick-up borough                     */
SELECT
    "borough"                       AS pickup_borough,
    ROUND( 100.0 *
           SUM( CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END ) 
           / COUNT(*), 2)           AS percent_no_tip
FROM   enriched
GROUP  BY "borough"
ORDER  BY percent_no_tip DESC NULLS LAST;