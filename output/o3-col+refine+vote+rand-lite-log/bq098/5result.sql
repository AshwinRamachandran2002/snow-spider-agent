WITH filtered AS (
  SELECT
    y.*,
    z.borough,
    -- tip-rate (%); treat 0-total as 0-tip
    CASE
      WHEN y.total_amount = 0 THEN 0
      ELSE (y.tip_amount * 100) / y.total_amount
    END AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`       AS z
       ON y.pickup_location_id = z.zone_id
  WHERE DATE(y.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'   -- pickup window
    AND DATE(y.dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'  -- drop-off window
    AND y.dropoff_datetime > y.pickup_datetime                          -- logical timing
    AND y.passenger_count  > 0
    AND y.trip_distance    >= 0
    AND y.tip_amount       >= 0
    AND y.tolls_amount     >= 0
    AND y.mta_tax          >= 0
    AND y.fare_amount      >= 0
    AND y.total_amount     >= 0
)
SELECT
  borough,
  COUNTIF(tip_rate = 0)                        AS no_tip_trips,
  COUNT(*)                                     AS total_trips,
  ROUND(SAFE_DIVIDE(COUNTIF(tip_rate = 0), 
                    COUNT(*)) * 100, 4)        AS pct_no_tip
FROM filtered
GROUP BY borough
ORDER BY pct_no_tip DESC;