WITH trips_filtered AS (
    /* 1.  Keep only valid yellow-cab trips picked up Jan 1 – Jan 7 2016
          and passing all quality / reasonableness checks                           */
    SELECT
        t."pickup_datetime",
        t."dropoff_datetime",
        t."pickup_location_id",
        t."passenger_count",
        t."trip_distance",
        t."tip_amount",
        t."tolls_amount",
        t."mta_tax",
        t."fare_amount",
        t."total_amount"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TLC_YELLOW_TRIPS_2016"  t
    WHERE  TO_TIMESTAMP(t."pickup_datetime"/1e6) BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
      AND  t."dropoff_datetime"  >  t."pickup_datetime"
      AND  t."passenger_count"   >  0
      AND  t."trip_distance"     >= 0
      AND  t."tip_amount"        >= 0
      AND  t."tolls_amount"      >= 0
      AND  t."mta_tax"           >= 0
      AND  t."fare_amount"       >= 0
      AND  t."total_amount"      >  0
),
trips_with_zone AS (
    /* 2.  Attach pickup-zone borough, drop EWR & Staten Island                     */
    SELECT
        z."borough"                                              AS "pickup_borough",
        t.*,
        100 * t."tip_amount" / t."total_amount"                  AS "tip_pct"
    FROM trips_filtered  t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM"  z
         ON t."pickup_location_id" = z."zone_id"
    WHERE z."borough" NOT IN ('EWR','Staten Island')
),
bucketed AS (
    /* 3.  Assign each trip to a tip-percentage bucket                              */
    SELECT
        "pickup_borough",
        CASE
            WHEN "tip_amount" = 0                       THEN 'no tip'
            WHEN "tip_pct"    <=  5                    THEN 'Less than 5%'
            WHEN "tip_pct"    <= 10                    THEN '5% to 10%'
            WHEN "tip_pct"    <= 15                    THEN '10% to 15%'
            WHEN "tip_pct"    <= 20                    THEN '15% to 20%'
            WHEN "tip_pct"    <= 25                    THEN '20% to 25%'
            ELSE                                           'More than 25%'
        END                                            AS "tip_bucket"
    FROM trips_with_zone
),
agg AS (
    /* 4.  Ride counts by borough & tip bucket                                       */
    SELECT
        "pickup_borough",
        "tip_bucket",
        COUNT(*) AS "rides"
    FROM bucketed
    GROUP BY "pickup_borough","tip_bucket"
)
/* 5.  Final output – share (%) of rides in each bucket within every borough        */
SELECT
    a."pickup_borough",
    a."tip_bucket",
    ROUND(100.0 * a."rides"
          / SUM(a."rides") OVER (PARTITION BY a."pickup_borough"), 2)  AS "percent_of_rides"
FROM agg a
ORDER BY a."pickup_borough", a."tip_bucket";