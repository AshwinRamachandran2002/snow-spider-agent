WITH filtered_trips AS (
    SELECT
        t."pickup_location_id",
        t."tip_amount",
        t."total_amount"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
    WHERE
        /* 1–7 Jan 2016 (inclusive) for BOTH pickup and drop-off */
        t."pickup_datetime"  >= 1451606400000000  -- 2016-01-01 00:00:00
        AND t."pickup_datetime"  < 1452211200000000  -- 2016-01-08 00:00:00
        AND t."dropoff_datetime" >= 1451606400000000
        AND t."dropoff_datetime" < 1452211200000000
        
        /* drop-off occurs after pickup */
        AND t."dropoff_datetime" > t."pickup_datetime"
        
        /* quality filters */
        AND t."passenger_count"  > 0
        AND t."trip_distance"    >= 0
        AND t."tip_amount"       >= 0
        AND t."tolls_amount"     >= 0
        AND t."mta_tax"          >= 0
        AND t."fare_amount"      >= 0
        AND t."total_amount"     >= 0
),
trips_with_tip AS (
    SELECT
        z."borough"                                            AS pickup_borough,
        CASE
            WHEN ft."total_amount" = 0 THEN 0
            ELSE (ft."tip_amount" * 100) / ft."total_amount"
        END                                                   AS tip_rate
    FROM filtered_trips ft
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM z
      ON ft."pickup_location_id" = z."zone_id"
    WHERE z."borough" IS NOT NULL
)
SELECT
    pickup_borough                                              AS "pickup_borough",
    ROUND(
        100.0 * SUM(CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*),0),
        4
    )                                                           AS "percent_no_tip"
FROM trips_with_tip
GROUP BY pickup_borough
ORDER BY pickup_borough;