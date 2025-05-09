SELECT
  z.borough AS pickup_borough,
  ROUND(COUNTIF(tip_rate = 0) * 100.0 / COUNT(*), 4) AS percentage_no_tip
FROM (
  SELECT
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    tip_amount,
    tolls_amount,
    mta_tax,
    fare_amount,
    total_amount,
    pickup_location_id,
    /* tip‑rate: treat as 0 when total_amount = 0 */
    CASE
      WHEN total_amount = 0 THEN 0
      ELSE SAFE_DIVIDE(tip_amount * 100, total_amount)
    END AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE DATE(pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND DATE(dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND dropoff_datetime > pickup_datetime
    AND passenger_count > 0
    AND trip_distance >= 0
    AND tip_amount   >= 0
    AND tolls_amount >= 0
    AND mta_tax      >= 0
    AND fare_amount  >= 0
    AND total_amount >= 0
) AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
  ON t.pickup_location_id = z.zone_id
GROUP BY pickup_borough
ORDER BY percentage_no_tip DESC, pickup_borough;