SELECT 
  z.borough AS Borough,
  ROUND(SUM(CASE WHEN t.tip_amount = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) AS Percentage_of_No_Tips
FROM 
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN 
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
ON 
  t.dropoff_location_id = z.zone_id
WHERE 
  t.pickup_datetime >= '2016-01-01' 
  AND t.pickup_datetime < '2016-01-08'
  AND t.dropoff_datetime > t.pickup_datetime
  AND t.passenger_count > 0
  AND t.trip_distance >= 0
  AND t.tip_amount >= 0
  AND t.tolls_amount >= 0
  AND t.mta_tax >= 0
  AND t.fare_amount >= 0
  AND t.total_amount >= 0
  AND t.tip_amount IS NOT NULL
  AND t.fare_amount IS NOT NULL
  AND t.total_amount IS NOT NULL
  AND t.trip_distance IS NOT NULL
  AND t.passenger_count IS NOT NULL
  AND t.dropoff_location_id IS NOT NULL
  AND z.borough IN ('Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island')
GROUP BY 
  z.borough
ORDER BY
  Percentage_of_No_Tips DESC;