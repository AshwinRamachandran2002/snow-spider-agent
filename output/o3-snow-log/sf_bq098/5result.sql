WITH trips AS (   -- add readable dates
    SELECT
        t.*,
        TO_DATE(TO_TIMESTAMP_LTZ(t."pickup_datetime"  / 1000000))  AS pickup_date ,
        TO_DATE(TO_TIMESTAMP_LTZ(t."dropoff_datetime" / 1000000))  AS dropoff_date
    FROM  NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016  t
),

filtered AS (      -- apply all requested filters
    SELECT
        t."pickup_location_id",
        CASE 
            WHEN t."total_amount" = 0 THEN 0
            ELSE (t."tip_amount" * 100) / t."total_amount"
        END                                                    AS tip_rate
    FROM trips t
    WHERE  pickup_date  BETWEEN '2016-01-01' AND '2016-01-07'
      AND  dropoff_date BETWEEN '2016-01-01' AND '2016-01-07'
      AND  t."dropoff_datetime" > t."pickup_datetime"
      AND  t."passenger_count" > 0
      AND  t."trip_distance"  >= 0
      AND  t."tip_amount"     >= 0
      AND  t."tolls_amount"   >= 0
      AND  t."mta_tax"        >= 0
      AND  t."fare_amount"    >= 0
      AND  t."total_amount"   >= 0
),

joined AS (        -- attach pickup-borough
    SELECT
        z."borough",
        CASE WHEN f.tip_rate = 0 THEN 1 ELSE 0 END  AS no_tip_flag
    FROM filtered f
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM z
          ON z."zone_id" = f."pickup_location_id"
)

SELECT
    "borough"                             AS pickup_borough,
    ROUND( (SUM(no_tip_flag)::FLOAT / COUNT(*)) * 100 , 4)  AS pct_no_tip
FROM joined
GROUP BY "borough"
ORDER BY pct_no_tip DESC NULLS LAST;