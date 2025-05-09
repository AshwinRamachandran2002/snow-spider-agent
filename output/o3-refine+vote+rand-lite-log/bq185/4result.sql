WITH brooklyn_trips AS (
  SELECT
    -- trip duration in minutes
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) / 60.0 AS duration_minutes
  FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN
    `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
    ON p.zone_id = t.pickup_location_id
  JOIN
    `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
    ON d.zone_id = t.dropoff_location_id
  WHERE
    -- Feb 1 – Feb 7 2016 inclusive
    t.pickup_datetime >= TIMESTAMP('2016-02-01 00:00:00')
    AND t.pickup_datetime <  TIMESTAMP('2016-02-08 00:00:00')
    
    -- both pickup and drop‑off in Brooklyn
    AND p.borough = 'Brooklyn'
    AND d.borough = 'Brooklyn'
    
    -- positive duration
    AND dropoff_datetime IS NOT NULL
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) > 0
    
    -- trip filters
    AND passenger_count > 3
    AND trip_distance >= 10
)

SELECT
  AVG(duration_minutes) AS average_trip_duration_minutes
FROM
  brooklyn_trips;