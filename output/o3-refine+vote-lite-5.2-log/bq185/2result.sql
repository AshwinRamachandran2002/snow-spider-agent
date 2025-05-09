SELECT
  AVG( TIMESTAMP_DIFF(tr.dropoff_datetime, tr.pickup_datetime, SECOND) ) / 60
    AS avg_trip_duration_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS tr
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS pz
  ON CAST(tr.pickup_location_id  AS STRING) = pz.zone_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS dz
  ON CAST(tr.dropoff_location_id AS STRING) = dz.zone_id
WHERE
      tr.pickup_datetime >= '2016-02-01 00:00:00'
  AND tr.pickup_datetime <  '2016-02-08 00:00:00'        -- Feb 1 – Feb 7 inclusive
  AND tr.passenger_count > 3                              -- more than three passengers
  AND tr.trip_distance  >= 10                             -- at least 10 miles
  AND TIMESTAMP_DIFF(tr.dropoff_datetime,
                     tr.pickup_datetime, SECOND) > 0      -- positive duration
  AND pz.borough = 'Brooklyn'                             -- pickup in Brooklyn
  AND dz.borough = 'Brooklyn'                             -- drop‑off in Brooklyn
;