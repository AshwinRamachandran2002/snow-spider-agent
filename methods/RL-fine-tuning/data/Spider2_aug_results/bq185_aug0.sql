-- Task: Calculate the average trip duration in minutes for all valid Yellow taxi trips from the `tlc_yellow_trips_2016` dataset that took place between February 1, 2016, and February 7, 2016 (inclusive), where both pickup and dropoff dates are within this range, the trip has a positive duration (dropoff_datetime is after pickup_datetime), carries more than three passengers, has a trip distance of at least ten miles, and where both the pickup and dropoff locations are in the borough of Brooklyn, as determined by matching `pickup_location_id` and `dropoff_location_id` with the `taxi_zone_geom` table.
SELECT 
    AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) / 60.0) AS average_trip_duration_in_minutes
FROM
(
    SELECT *
    FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` t
    WHERE 
        pickup_datetime BETWEEN '2016-02-01' AND '2016-02-07' AND 
        dropoff_datetime BETWEEN '2016-02-01' AND '2016-02-07' AND
        TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) > 0 AND 
        passenger_count > 3 AND 
        trip_distance >= 10
) t
INNER JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` tz
ON t.pickup_location_id = tz.zone_id
INNER JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` tz1
ON t.dropoff_location_id = tz1.zone_id
WHERE 
    tz.borough = "Brooklyn" AND
    tz1.borough = "Brooklyn";