/*  Percentage of “no-tip” yellow-taxi trips (pick-ups 1–7 Jan 2016) by pick-up borough  */

WITH trips_2016 AS (          -- keep only the 1–7 Jan 2016 qualified trips
    SELECT
        t.* ,
        /* tip-rate (0 when total_amount = 0) */
        CASE
            WHEN "total_amount" > 0
                 THEN ("tip_amount" * 100.0) / "total_amount"
            ELSE 0
        END                                                  AS tip_rate
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
    WHERE
          /* pick-up & drop-off date window (note: epoch values are in µs) */
          TO_DATE( TO_TIMESTAMP_NTZ( "pickup_datetime"  / 1000000 ) ) BETWEEN '2016-01-01' AND '2016-01-07'
      AND TO_DATE( TO_TIMESTAMP_NTZ( "dropoff_datetime" / 1000000 ) ) BETWEEN '2016-01-01' AND '2016-01-07'
      /* data-quality filters  */
      AND "dropoff_datetime" > "pickup_datetime"
      AND "passenger_count"  > 0
      AND "trip_distance"    >= 0
      AND "tip_amount"       >= 0
      AND "tolls_amount"     >= 0
      AND "mta_tax"          >= 0
      AND "fare_amount"      >= 0
      AND "total_amount"     >= 0
)

SELECT
    z."borough"                                           AS "pickup_borough",
    ROUND( 100.0 * SUM( CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END )
                 / COUNT(*) , 4)                          AS "percent_no_tip"
FROM trips_2016   t
JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM z
     ON t."pickup_location_id" = z."zone_id"
GROUP BY z."borough"
ORDER BY z."borough";