WITH brooklyn_zones AS (
  SELECT zone_id
  FROM `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`
  WHERE LOWER(borough) = 'brooklyn'
),

eligible_trips AS (
  SELECT
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS trip_minutes
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS yt
  WHERE
        DATE(pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) > 0          -- positive duration
    AND passenger_count > 3                                                    -- more than three passengers
    AND trip_distance >= 10                                                    -- at least ten miles
    AND CAST(pickup_location_id  AS STRING) IN (SELECT zone_id FROM brooklyn_zones)
    AND CAST(dropoff_location_id AS STRING) IN (SELECT zone_id FROM brooklyn_zones)
)

SELECT
  AVG(trip_minutes) AS average_trip_duration_minutes
FROM eligible_trips;