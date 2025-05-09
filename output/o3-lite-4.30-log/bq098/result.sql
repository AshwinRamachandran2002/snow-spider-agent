WITH filtered AS (
  SELECT
    z.borough AS pickup_borough,
    COALESCE(              -- 0 when total_amount = 0
      SAFE_DIVIDE(t.tip_amount * 100, t.total_amount),
      0
    ) AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
    ON t.pickup_location_id = z.zone_id
  WHERE
        t.pickup_datetime  BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
    AND t.dropoff_datetime BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count  > 0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount      >= 0
    AND t.total_amount     >= 0
)
SELECT
  pickup_borough,
  ROUND(100 * COUNTIF(tip_rate = 0) / COUNT(*), 4) AS percentage_no_tip
FROM filtered
GROUP BY pickup_borough
ORDER BY percentage_no_tip DESC, pickup_borough;