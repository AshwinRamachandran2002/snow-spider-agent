WITH eligible_trips AS (      -- trips that satisfy all study-window & data-quality filters
    SELECT
        z."borough" AS "pickup_borough",
        /* tip percentage = tip ÷ (total – tip) */
        CASE
            WHEN (t."total_amount" - t."tip_amount") > 0 THEN
                 (t."tip_amount" / NULLIF((t."total_amount" - t."tip_amount"),0)) * 100
            ELSE 0
        END AS "tip_pct"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM        z
      ON z."zone_id" = t."pickup_location_id"
    WHERE t."pickup_datetime" >= 1451606400000000          -- 2016-01-01 00:00:00
      AND t."pickup_datetime" <  1452211200000000          -- 2016-01-08 00:00:00
      AND t."dropoff_datetime" >  t."pickup_datetime"
      AND t."passenger_count"  >  0
      AND t."trip_distance"    >= 0
      AND t."tip_amount"       >= 0
      AND t."tolls_amount"     >= 0
      AND t."mta_tax"          >= 0
      AND t."fare_amount"      >= 0
      AND t."total_amount"     >= 0
      AND z."borough" NOT IN ('EWR','Staten Island')
),

bucketed AS (                -- assign each trip to a tip-percentage bucket
    SELECT
        "pickup_borough",
        CASE
            WHEN "tip_pct" = 0           THEN '0% (no tip)'
            WHEN "tip_pct" <= 5          THEN 'up to 5%'
            WHEN "tip_pct" <= 10         THEN '5% to 10%'
            WHEN "tip_pct" <= 15         THEN '10% to 15%'
            WHEN "tip_pct" <= 20         THEN '15% to 20%'
            WHEN "tip_pct" <= 25         THEN '20% to 25%'
            ELSE                             'more than 25%'
        END AS "tip_bucket"
    FROM eligible_trips
)

SELECT
    "pickup_borough",
    "tip_bucket",
    COUNT(*)                                       AS "ride_count",
    ROUND(
        COUNT(*)::FLOAT /
        SUM(COUNT(*)) OVER (PARTITION BY "pickup_borough")
    , 4)                                           AS "proportion_of_rides"
FROM bucketed
GROUP BY
    "pickup_borough",
    "tip_bucket"
ORDER BY
    "pickup_borough",
    "tip_bucket";