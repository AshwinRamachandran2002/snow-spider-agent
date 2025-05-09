SELECT
  z.borough AS Borough,
  ROUND(COUNTIF(t.tip_amount = 0) * 100.0 / COUNT(*), 4) AS Percentage_of_No_Tips
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` t
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
ON
  t.dropoff_location_id = z.zone_id
WHERE
  DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
  AND t.dropoff_datetime > t.pickup_datetime
  AND t.passenger_count > 0
  AND t.trip_distance >= 0
  AND t.tip_amount >= 0
  AND t.tolls_amount >= 0
  AND t.mta_tax >= 0
  AND t.fare_amount >= 0
  AND t.total_amount >= 0
  AND z.borough != 'EWR'
GROUP BY
  z.borough
ORDER BY
  z.borough;