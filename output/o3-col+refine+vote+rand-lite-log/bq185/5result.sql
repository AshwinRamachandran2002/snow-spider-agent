WITH brooklyn_zones AS (
  SELECT zone_id
  FROM `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`
  WHERE LOWER(borough) = 'brooklyn'
),
filtered_trips AS (
  SELECT
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS trip_minutes
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE DATE(pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'
    AND passenger_count > 3
    AND trip_distance >= 10
    AND pickup_location_id IN (SELECT zone_id FROM brooklyn_zones)
    AND dropoff_location_id IN (SELECT zone_id FROM brooklyn_zones)
    AND dropoff_datetime IS NOT NULL
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) > 0
)
SELECT
  AVG(trip_minutes) AS average_trip_minutes
FROM filtered_trips;