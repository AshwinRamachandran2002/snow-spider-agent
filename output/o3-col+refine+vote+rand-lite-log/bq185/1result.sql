-- Average duration (in minutes) of Yellow-cab trips that meet all stated criteria
SELECT
  AVG( TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) )
    AS avg_trip_duration_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS pu
  ON t.pickup_location_id  = pu.zone_id          -- pickup zone details
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS do
  ON t.dropoff_location_id = do.zone_id          -- drop-off zone details
WHERE DATE(t.pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'  -- target week
  AND LOWER(pu.borough) = 'brooklyn'                                -- pickup in Brooklyn
  AND LOWER(do.borough) = 'brooklyn'                                -- drop-off in Brooklyn
  AND t.passenger_count > 3                                         -- more than 3 passengers
  AND t.trip_distance   >= 10                                        -- at least 10 miles
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0; -- positive duration