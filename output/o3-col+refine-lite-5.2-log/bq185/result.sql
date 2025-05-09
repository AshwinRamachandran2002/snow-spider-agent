-- Average duration (in minutes) of valid Yellow‑cab trips during 1–7 Feb 2016
SELECT
  AVG( TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) ) AS avg_trip_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS pickup_zone
  ON CAST(t.pickup_location_id AS STRING) = pickup_zone.zone_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS dropoff_zone
  ON CAST(t.dropoff_location_id AS STRING) = dropoff_zone.zone_id
WHERE
  t.pickup_datetime BETWEEN '2016-02-01' AND '2016-02-07 23:59:59'
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) > 0   -- positive duration
  AND t.passenger_count > 3                                              -- more than 3 passengers
  AND t.trip_distance >= 10                                              -- at least 10 miles
  AND pickup_zone.borough = 'Brooklyn'                                   -- pickup in Brooklyn
  AND dropoff_zone.borough = 'Brooklyn';                                 -- drop‑off in Brooklyn