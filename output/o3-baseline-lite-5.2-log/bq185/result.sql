-- average trip duration (in minutes) for qualifying Yellow taxi rides
SELECT
  AVG(duration_minutes) AS average_trip_duration_minutes
FROM (
  SELECT
    TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) AS duration_minutes
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
    ON t.pickup_location_id = p.zone_id
   AND p.borough = 'Brooklyn'                          -- pickup in Brooklyn
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
    ON t.dropoff_location_id = d.zone_id
   AND d.borough = 'Brooklyn'                          -- drop‑off in Brooklyn
  WHERE
        t.pickup_datetime BETWEEN TIMESTAMP('2016-02-01 00:00:00')
                             AND TIMESTAMP('2016-02-07 23:59:59') -- Feb 1‑7 2016 inclusive
    AND t.dropoff_datetime IS NOT NULL
    AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) > 0  -- positive duration
    AND t.passenger_count > 3                                              -- more than 3 passengers
    AND t.trip_distance >= 10                                              -- at least 10 miles
);