SELECT
  ROUND(
        AVG(TIMESTAMP_DIFF(t.dropoff_datetime,
                           t.pickup_datetime,
                           SECOND)) / 60,
        4) AS average_trip_duration_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS tz_pick
  ON t.pickup_location_id = tz_pick.zone_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS tz_drop
  ON t.dropoff_location_id = tz_drop.zone_id
WHERE DATE(t.pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0
  AND t.passenger_count > 3
  AND t.trip_distance >= 10
  AND tz_pick.borough = 'Brooklyn'
  AND tz_drop.borough = 'Brooklyn';