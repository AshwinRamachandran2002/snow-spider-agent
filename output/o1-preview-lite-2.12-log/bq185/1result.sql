SELECT AVG(TIMESTAMP_DIFF(`dropoff_datetime`, `pickup_datetime`, MINUTE)) AS `average_trip_duration_minutes`
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
WHERE DATE(`pickup_datetime`) BETWEEN '2016-02-01' AND '2016-02-07'
  AND TIMESTAMP_DIFF(`dropoff_datetime`, `pickup_datetime`, MINUTE) > 0
  AND `passenger_count` > 3
  AND `trip_distance` >= 10
  AND `pickup_location_id` IN (
    SELECT `zone_id`
    FROM `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`
    WHERE LOWER(`borough`) = 'brooklyn'
  )
  AND `dropoff_location_id` IN (
    SELECT `zone_id`
    FROM `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`
    WHERE LOWER(`borough`) = 'brooklyn'
  );