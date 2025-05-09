WITH top_20_bike_routes AS (
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
  LIMIT 20
),
taxi_routes AS (
  SELECT
    ROUND(pickup_latitude, 3) AS start_latitude,
    ROUND(pickup_longitude, 3) AS start_longitude,
    ROUND(dropoff_latitude, 3) AS end_latitude,
    ROUND(dropoff_longitude, 3) AS end_longitude,
    AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)) AS avg_taxi_duration_seconds
  FROM
    `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE
    pickup_latitude IS NOT NULL
    AND pickup_longitude IS NOT NULL
    AND dropoff_latitude IS NOT NULL
    AND dropoff_longitude IS NOT NULL
    AND pickup_latitude != 0.0
    AND pickup_longitude != 0.0
    AND dropoff_latitude != 0.0
    AND dropoff_longitude != 0.0
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) BETWEEN 60 AND 7200
  GROUP BY
    start_latitude,
    start_longitude,
    end_latitude,
    end_longitude
)
SELECT
  b.start_station_name
FROM
  top_20_bike_routes b
JOIN
  taxi_routes t
ON
  b.start_latitude = t.start_latitude
  AND b.start_longitude = t.start_longitude
  AND b.end_latitude = t.end_latitude
  AND b.end_longitude = t.end_longitude
WHERE
  b.avg_bike_duration_seconds < t.avg_taxi_duration_seconds
ORDER BY
  b.avg_bike_duration_seconds DESC
LIMIT 1;