SELECT
  ROUND(AVG(TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, MINUTE)), 4) AS average_trip_duration_minutes
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
    ON y.pickup_location_id = p.zone_id
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
    ON y.dropoff_location_id = d.zone_id
WHERE
  DATE(y.pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'
  AND TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND) > 0
  AND y.passenger_count > 3
  AND y.trip_distance >= 10
  AND LOWER(p.borough) = 'brooklyn'
  AND LOWER(d.borough) = 'brooklyn';