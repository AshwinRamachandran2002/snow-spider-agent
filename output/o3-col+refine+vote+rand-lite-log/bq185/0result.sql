-- Average trip duration (minutes) for qualifying Yellow Taxi rides in Brooklyn
WITH brooklyn_trips AS (
  SELECT
    TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, MINUTE) AS duration_min
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
    ON y.pickup_location_id = p.zone_id
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
    ON y.dropoff_location_id = d.zone_id
  WHERE y.pickup_datetime >= '2016-02-01'
    AND y.pickup_datetime <  '2016-02-08'           -- through 2016-02-07 23:59:59
    AND p.borough = 'Brooklyn'                      -- pickup in Brooklyn
    AND d.borough = 'Brooklyn'                      -- drop-off in Brooklyn
    AND y.passenger_count  > 3                      -- more than three passengers
    AND y.trip_distance    >= 10                    -- at least ten miles
    AND TIMESTAMP_DIFF(y.dropoff_datetime,
                       y.pickup_datetime, MINUTE) > 0   -- positive duration
)
SELECT
  AVG(duration_min) AS avg_trip_duration_minutes
FROM brooklyn_trips;