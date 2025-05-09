WITH filtered_trips AS (
    SELECT
        z.borough                   AS pickup_borough,
        t.tip_amount,
        t.total_amount
    FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
    JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`         AS z
      ON t.pickup_location_id = z.zone_id
    WHERE
          -- week of Jan‑01 to Jan‑07 2016  (inclusive)
          t.pickup_datetime >= '2016-01-01 00:00:00'
      AND t.pickup_datetime <  '2016-01-08 00:00:00'
      AND t.dropoff_datetime >  t.pickup_datetime                 -- logical trip
      AND t.passenger_count   >  0
      AND t.trip_distance     >= 0
      AND t.tip_amount        >= 0
      AND t.tolls_amount      >= 0
      AND t.mta_tax           >= 0
      AND t.fare_amount       >= 0
      AND t.total_amount      >= 0
      -- exclude EWR and Staten Island pick‑ups
      AND z.borough NOT IN ('EWR','Staten Island')
),
tip_bins AS (
    SELECT
        pickup_borough,
        CASE
            WHEN tip_amount = 0 THEN 'no tip'
            ELSE
              CASE
                WHEN tip_pct  <=   5 THEN 'Less than 5%'
                WHEN tip_pct  <=  10 THEN '5% to 10%'
                WHEN tip_pct  <=  15 THEN '10% to 15%'
                WHEN tip_pct  <=  20 THEN '15% to 20%'
                WHEN tip_pct  <=  25 THEN '20% to 25%'
                ELSE                'More than 25%'
              END
        END AS tip_category
    FROM (
        SELECT
            pickup_borough,
            -- tip percentage; if denominator is zero, treat as 0
            CASE
                WHEN (total_amount - tip_amount) > 0
                     THEN 100 * SAFE_DIVIDE(tip_amount, total_amount - tip_amount)
                ELSE 0
            END AS tip_pct,
            tip_amount
        FROM filtered_trips
    )
)
SELECT
    pickup_borough,
    tip_category,
    COUNT(*)                                           AS rides,
    SAFE_DIVIDE(COUNT(*),
                SUM(COUNT(*)) OVER (PARTITION BY pickup_borough)
               )                                       AS proportion
FROM tip_bins
GROUP BY
    pickup_borough,
    tip_category
ORDER BY
    pickup_borough,
    tip_category;