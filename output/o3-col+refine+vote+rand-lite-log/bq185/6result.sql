-- Average trip duration (minutes) for Yellow taxi rides in Brooklyn, Feb 1–7 2016
SELECT
  AVG(trip_minutes) AS avg_trip_minutes
FROM (
  SELECT
    TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) AS trip_minutes
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
    ON t.pickup_location_id = p.zone_id
   AND p.borough = 'Brooklyn'
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
    ON t.dropoff_location_id = d.zone_id
   AND d.borough = 'Brooklyn'
  WHERE DATE(t.pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'
    AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0
    AND t.passenger_count > 3
    AND t.trip_distance  >= 10
);