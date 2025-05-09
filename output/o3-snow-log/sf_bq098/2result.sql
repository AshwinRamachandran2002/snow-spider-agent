WITH trips AS (
    SELECT
        z."borough"                           AS "pickup_borough",
        t."tip_amount",
        t."total_amount",
        /* tip-rate: 0 when total_amount is 0 to avoid division by zero                */
        CASE 
            WHEN COALESCE(t."total_amount",0) = 0 
                 THEN 0
            ELSE (COALESCE(t."tip_amount",0) * 100) / t."total_amount"
        END                                     AS "tip_rate"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
    /* join to get pickup-borough                                                    */
    LEFT JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM z
           ON z."zone_id" = t."pickup_location_id"
    WHERE
          z."borough" IS NOT NULL
      /*-- pickup & drop-off must both be between 1-Jan-2016 and 7-Jan-2016 inclusive */
      AND TO_TIMESTAMP_LTZ(t."pickup_datetime"  / 1000000) BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
      AND TO_TIMESTAMP_LTZ(t."dropoff_datetime" / 1000000) BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
      /* drop-off occurs after pickup                                                */
      AND t."dropoff_datetime" > t."pickup_datetime"
      /* trip quality filters                                                        */
      AND COALESCE(t."passenger_count",0)                > 0
      AND COALESCE(t."trip_distance",0)                  >= 0
      AND COALESCE(t."tip_amount",0)                     >= 0
      AND COALESCE(t."tolls_amount",0)                   >= 0
      AND COALESCE(t."mta_tax",0)                        >= 0
      AND COALESCE(t."fare_amount",0)                    >= 0
      AND COALESCE(t."total_amount",0)                   >= 0
)
SELECT
    "pickup_borough",
    ROUND( 100.0 * SUM(CASE WHEN "tip_rate" = 0 THEN 1 ELSE 0 END) 
           / COUNT(*) , 2)                               AS "percent_no_tip"
FROM trips
GROUP BY "pickup_borough"
ORDER BY "percent_no_tip" DESC NULLS LAST;