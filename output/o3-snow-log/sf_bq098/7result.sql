WITH filtered_trips AS (
    SELECT
        t.*,
        /* calculate tip rate – treat as zero if total_amount is zero */
        CASE 
            WHEN "total_amount" = 0 THEN 0
            ELSE ("tip_amount" * 100) / "total_amount"
        END                                                   AS tip_rate
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
    WHERE
          /* trips picked-up between 2016-01-01 and 2016-01-07 (inclusive) */
          "pickup_datetime"  >= 1451606400000000   -- 2016-01-01 00:00:00
      AND "pickup_datetime"  <  1452211200000000   -- 2016-01-08 00:00:00

          /* drop-offs in the same period and after the pickup */
      AND "dropoff_datetime" >= 1451606400000000
      AND "dropoff_datetime" <  1452211200000000
      AND "dropoff_datetime"  > "pickup_datetime"

          /* data-quality filters */
      AND "passenger_count"  > 0
      AND "trip_distance"    >= 0
      AND "tip_amount"       >= 0
      AND "tolls_amount"     >= 0
      AND "mta_tax"          >= 0
      AND "fare_amount"      >= 0
      AND "total_amount"     >= 0
)
SELECT
    tz."borough"                                                                 AS "pickup_borough",
    ROUND(
        100.0 * SUM(CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END) / COUNT(*)
    , 2)                                                                         AS "pct_no_tip"
FROM filtered_trips ft
JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM tz
  ON tz."zone_id" = ft."pickup_location_id"
GROUP BY tz."borough"
ORDER BY tz."borough";