WITH filtered AS (
  SELECT
    y.pickup_location_id,
    -- tip-rate (%) – treat zero-total as zero tip-rate
    CASE
      WHEN y.total_amount = 0 THEN 0
      ELSE (y.tip_amount * 100) / y.total_amount
    END AS tip_rate_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
  WHERE DATE(y.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND DATE(y.dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND y.dropoff_datetime > y.pickup_datetime              -- logical trip
    AND y.passenger_count > 0                               -- at least one rider
    AND y.trip_distance  >= 0
    AND y.tip_amount     >= 0
    AND y.tolls_amount   >= 0
    AND y.mta_tax        >= 0
    AND y.fare_amount    >= 0
    AND y.total_amount   >= 0
)

SELECT
  z.borough                                                        AS pickup_borough,
  COUNT(*)                                                         AS total_trips,
  SUM(CASE WHEN tip_rate_pct = 0 THEN 1 ELSE 0 END)               AS no_tip_trips,
  ROUND(100 * SUM(CASE WHEN tip_rate_pct = 0 THEN 1 ELSE 0 END)
            / COUNT(*), 2)                                         AS pct_no_tip
FROM filtered
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
ON   filtered.pickup_location_id = z.zone_id
GROUP BY pickup_borough
ORDER BY pct_no_tip DESC;