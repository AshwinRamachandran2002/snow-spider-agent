SELECT
  AVG( TIMESTAMP_DIFF(yt.dropoff_datetime, yt.pickup_datetime, MINUTE) ) AS avg_trip_duration_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS yt
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS tzp
  ON yt.pickup_location_id = tzp.zone_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS tzd
  ON yt.dropoff_location_id = tzd.zone_id
WHERE yt.pickup_datetime BETWEEN '2016-02-01' AND '2016-02-07 23:59:59'
  AND yt.passenger_count > 3
  AND yt.trip_distance >= 10
  AND tzp.borough = 'Brooklyn'
  AND tzd.borough = 'Brooklyn'
  AND yt.dropoff_datetime IS NOT NULL
  AND TIMESTAMP_DIFF(yt.dropoff_datetime, yt.pickup_datetime, SECOND) > 0;