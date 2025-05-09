-- average trip duration (in minutes) for qualifying 2016 yellow‑cab rides
WITH feb_yellow AS (
  SELECT
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    pickup_location_id,
    dropoff_location_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE DATE(pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'      -- Feb 1–7 2016, inclusive
),
brooklyn_trips AS (
  SELECT
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS trip_minutes
  FROM feb_yellow y
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z_pick
    ON y.pickup_location_id = z_pick.zone_id
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z_drop
    ON y.dropoff_location_id = z_drop.zone_id
  WHERE
        z_pick.borough  = 'Brooklyn'           -- pickup in Brooklyn
    AND z_drop.borough  = 'Brooklyn'           -- drop‑off in Brooklyn
    AND trip_distance   >= 10                  -- at least 10 miles
    AND passenger_count >  3                   -- more than 3 passengers
    AND dropoff_datetime > pickup_datetime     -- positive duration
)
SELECT
  AVG(trip_minutes) AS avg_trip_duration_minutes
FROM brooklyn_trips;