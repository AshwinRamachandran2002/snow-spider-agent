-- Task: List the top 20 Citi Bike routes in 2016 by number of trips, including the start station name, rounded coordinates, trip count, and average bike duration.

SELECT
    start_station_name,
    ROUND(start_station_latitude, 3) AS start_latitude,
    ROUND(start_station_longitude, 3) AS start_longitude,
    ROUND(end_station_latitude, 3) AS end_latitude,
    ROUND(end_station_longitude, 3) AS end_longitude,
    COUNT(*) AS bike_trip_count,
    AVG(tripduration) AS avg_bike_duration_seconds
FROM
    `bigquery-public-data.new_york.citibike_trips`
WHERE
    EXTRACT(YEAR FROM starttime) = 2016
    AND start_station_latitude IS NOT NULL
    AND start_station_longitude IS NOT NULL
    AND end_station_latitude IS NOT NULL
    AND end_station_longitude IS NOT NULL
    AND start_station_latitude != 0.0
    AND start_station_longitude != 0.0
    AND end_station_latitude != 0.0
    AND end_station_longitude != 0.0
GROUP BY
    start_station_name,
    start_latitude,
    start_longitude,
    end_latitude,
    end_longitude
ORDER BY
    bike_trip_count DESC
LIMIT 20;