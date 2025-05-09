SELECT
  ROUND(AVG(TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE)), 4) AS Average_trip_duration_minutes
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
    ON t.pickup_location_id = z.zone_id
WHERE
  t.passenger_count > 3
  AND t.trip_distance >= 10
  AND DATE(t.pickup_datetime, 'America/New_York') BETWEEN '2016-02-01' AND '2016-02-07'
  AND z.borough = 'Brooklyn'
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) > 0;