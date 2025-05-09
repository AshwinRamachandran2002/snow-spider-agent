-- Average duration (minutes) of qualifying Yellow-taxi trips, Feb 1–7 2016
WITH brooklyn_zones AS (
  SELECT zone_id
  FROM `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`
  WHERE borough = 'Brooklyn'
)

SELECT
  AVG( TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) ) AS avg_trip_duration_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN brooklyn_zones AS pz ON t.pickup_location_id  = pz.zone_id   -- pickup in Brooklyn
JOIN brooklyn_zones AS dz ON t.dropoff_location_id = dz.zone_id   -- drop-off in Brooklyn
WHERE DATE(t.pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) > 0
  AND t.passenger_count > 3
  AND CAST(t.trip_distance AS FLOAT64) >= 10;