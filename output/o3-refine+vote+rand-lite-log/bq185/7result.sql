WITH eligible_trips AS (
  SELECT
    TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, MINUTE) AS trip_duration_minutes
  FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
  JOIN
    `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
    ON p.zone_id = y.pickup_location_id
  JOIN
    `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
    ON d.zone_id = y.dropoff_location_id
  WHERE
        y.pickup_datetime >= '2016-02-01 00:00:00'
    AND y.pickup_datetime <  '2016-02-08 00:00:00'      -- up to and including Feb‑07
    AND TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND) > 0
    AND y.passenger_count > 3                           -- more than three passengers
    AND y.trip_distance >= 10                           -- at least ten miles
    AND p.borough = 'Brooklyn'                          -- pickup in Brooklyn
    AND d.borough = 'Brooklyn'                          -- drop‑off in Brooklyn
)

SELECT
  AVG(trip_duration_minutes) AS avg_trip_duration_minutes
FROM
  eligible_trips;