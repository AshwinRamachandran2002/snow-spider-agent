WITH filtered AS (

    SELECT
        z."borough"                                                             AS "pickup_borough",
        /* ----- tip-percentage bucket --------------------------------------- */
        CASE
            WHEN t."tip_amount" = 0 THEN '0% (no tip)'
            WHEN (t."tip_amount"/NULLIF(t."total_amount",0))*100 <=  5 THEN 'Up to 5%'
            WHEN (t."tip_amount"/NULLIF(t."total_amount",0))*100 <= 10 THEN '5% to 10%'
            WHEN (t."tip_amount"/NULLIF(t."total_amount",0))*100 <= 15 THEN '10% to 15%'
            WHEN (t."tip_amount"/NULLIF(t."total_amount",0))*100 <= 20 THEN '15% to 20%'
            WHEN (t."tip_amount"/NULLIF(t."total_amount",0))*100 <= 25 THEN '20% to 25%'
            ELSE                                            'More than 25%'
        END                                                                     AS "tip_bucket"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016  t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM         z
          ON t."pickup_location_id" = z."zone_id"
    /* -------- filters ------------------------------------------------------ */
    WHERE t."pickup_datetime"  >= 1451606400000000      -- 2016-01-01 00:00
      AND t."pickup_datetime"  < 1452211200000000      -- 2016-01-08 00:00
      AND t."dropoff_datetime" >  t."pickup_datetime"   -- logical trip
      AND t."passenger_count"  >  0
      AND t."trip_distance"    >= 0
      AND t."tip_amount"       >= 0
      AND t."tolls_amount"     >= 0
      AND t."mta_tax"          >= 0
      AND t."fare_amount"      >= 0
      AND t."total_amount"     >  0
      AND z."borough" NOT IN ('EWR','Staten Island')    -- exclude Newark & SI
)

SELECT
    "pickup_borough",
    "tip_bucket",
    COUNT(*)                                                     AS "rides",
    ROUND( COUNT(*) * 100.0
           / SUM(COUNT(*)) OVER (PARTITION BY "pickup_borough")
         , 2)                                                    AS "percent_of_borough"
FROM filtered
GROUP BY "pickup_borough", "tip_bucket"
ORDER BY "pickup_borough", "tip_bucket";