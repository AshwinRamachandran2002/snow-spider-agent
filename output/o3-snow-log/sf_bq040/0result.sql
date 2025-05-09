/*  Proportion of yellow-cab rides (1-7 Jan 2016) in each tip-rate bucket,
    by pickup borough, excluding trips that originated in Staten Island
    or at Newark Airport (EWR).                                           */

WITH jan16_trips AS (
    SELECT
        z."borough"                                         AS "pickup_borough",
        /* ----------- tip-rate bucket ------------------- */
        CASE
            WHEN t."tip_amount" = 0                                                        THEN 'no tip'
            WHEN 100 * t."tip_amount" / NULLIF(t."total_amount" - t."tip_amount", 0) <=  5 THEN 'Less than 5%'
            WHEN 100 * t."tip_amount" / NULLIF(t."total_amount" - t."tip_amount", 0) <= 10 THEN '5% to 10%'
            WHEN 100 * t."tip_amount" / NULLIF(t."total_amount" - t."tip_amount", 0) <= 15 THEN '10% to 15%'
            WHEN 100 * t."tip_amount" / NULLIF(t."total_amount" - t."tip_amount", 0) <= 20 THEN '15% to 20%'
            WHEN 100 * t."tip_amount" / NULLIF(t."total_amount" - t."tip_amount", 0) <= 25 THEN '20% to 25%'
            ELSE                                                                               'More than 25%'
        END                                            AS "tip_bucket"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM        z
           ON z."zone_id" = t."pickup_location_id"
    WHERE
          /* 1 Jan 2016 00:00:00 ➜ 7 Jan 2016 23:59:59 (microseconds) */
          t."pickup_datetime" BETWEEN 1451606400000000 AND 1452124799000000
      AND t."dropoff_datetime" >  t."pickup_datetime"
      AND t."passenger_count"  >  0
      AND t."trip_distance"    >= 0
      AND t."tip_amount"       >= 0
      AND t."tolls_amount"     >= 0
      AND t."mta_tax"          >= 0
      AND t."fare_amount"      >= 0
      AND t."total_amount"     >= 0
      AND z."borough" NOT IN ('Staten Island', 'EWR')  -- exclude SI & Newark Airport
)

, trip_counts AS (
    SELECT
        "pickup_borough",
        "tip_bucket",
        COUNT(*) AS "trip_count"
    FROM jan16_trips
    GROUP BY "pickup_borough", "tip_bucket"
)

SELECT
    "pickup_borough",
    "tip_bucket",
    ROUND(
        100.0 * "trip_count"
        / SUM("trip_count") OVER (PARTITION BY "pickup_borough")
    , 2)                                                  AS "pct_of_trips"
FROM trip_counts
ORDER BY "pickup_borough", "tip_bucket";