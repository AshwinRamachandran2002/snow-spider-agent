SELECT
  AVG(trip_minutes) AS avg_trip_duration_minutes
FROM (
  SELECT
    TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) AS trip_minutes
  FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN
    `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z_pick
    ON t.pickup_location_id = z_pick.zone_id
  JOIN
    `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z_drop
    ON t.dropoff_location_id = z_drop.zone_id
  WHERE
    -- trip took place between Feb 1 and Feb 7, 2016 (inclusive)
    t.pickup_datetime >= TIMESTAMP('2016-02-01 00:00:00', 'UTC')
    AND t.pickup_datetime <  TIMESTAMP('2016-02-08 00:00:00', 'UTC')
    -- valid, positive‐length trips
    AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0
    -- trip criteria
    AND t.passenger_count > 3
    AND t.trip_distance >= 10
    -- both pickup and drop‑off in Brooklyn
    AND z_pick.borough = 'Brooklyn'
    AND z_drop.borough = 'Brooklyn'
)