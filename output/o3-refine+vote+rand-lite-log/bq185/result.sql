-- Average duration (in minutes) of valid Yellow Taxi trips, Feb 1 – Feb 7 2016,
-- with >3 passengers, distance ≥ 10 mi, Brooklyn → Brooklyn
SELECT
  ROUND(AVG(duration_minutes), 4) AS avg_trip_duration_minutes
FROM (
  SELECT
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS duration_minutes
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS p
    ON t.pickup_location_id  = p.zone_id
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS d
    ON t.dropoff_location_id = d.zone_id
  WHERE
        -- trip date window (inclusive)
        t.pickup_datetime >= '2016-02-01 00:00:00'
    AND t.pickup_datetime <  '2016-02-08 00:00:00'
        -- positive duration
    AND dropoff_datetime > pickup_datetime
        -- required trip / rider filters
    AND t.passenger_count > 3
    AND t.trip_distance     >= 10
        -- both ends in Brooklyn
    AND p.borough = 'Brooklyn'
    AND d.borough = 'Brooklyn'
);