-- Task: What is the average trip duration in minutes for all valid Yellow taxi trips that took place between February 1, 2016, and February 7, 2016 (inclusive), with a positive trip duration, more than three passengers, and a trip distance of at least ten miles?

SELECT 
    AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) / 60.0) AS average_trip_duration_in_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
WHERE 
    pickup_datetime BETWEEN '2016-02-01' AND '2016-02-07' AND 
    dropoff_datetime BETWEEN '2016-02-01' AND '2016-02-07' AND
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) > 0 AND 
    passenger_count > 3 AND 
    trip_distance >= 10;