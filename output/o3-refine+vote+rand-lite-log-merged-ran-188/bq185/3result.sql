-- average trip duration (in minutes) for qualifying Yellow Taxi rides
SELECT
  AVG(trip_duration_minutes) AS avg_trip_duration_minutes
FROM (
  SELECT
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) / 60.0 AS trip_duration_minutes
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
    ON CAST(t.pickup_location_id AS STRING) = p.zone_id
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
    ON CAST(t.dropoff_location_id AS STRING) = d.zone_id
  WHERE
        DATE(pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'          -- required week
    AND passenger_count > 3                                                   -- more than three passengers
    AND trip_distance >= 10                                                   -- at least 10 miles
    AND p.borough = 'Brooklyn'                                                -- pickup in Brooklyn
    AND d.borough = 'Brooklyn'                                                -- drop‑off in Brooklyn
    AND dropoff_datetime > pickup_datetime                                    -- positive duration
)