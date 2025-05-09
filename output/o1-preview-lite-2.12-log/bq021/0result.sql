WITH top_routes AS (
  SELECT
    start_station_id,
    start_station_name,
    end_station_id,
    end_station_name,
    ROUND(start_station_latitude, 3) AS start_lat,
    ROUND(start_station_longitude, 3) AS start_lon,
    ROUND(end_station_latitude, 3) AS end_lat,
    ROUND(end_station_longitude, 3) AS end_lon,
    COUNT(*) AS trip_count,
    ROUND(AVG(tripduration) / 60, 4) AS avg_bike_duration_minutes
  FROM
    `bigquery-public-data.new_york.citibike_trips`
  WHERE
    EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY
    start_station_id,
    start_station_name,
    end_station_id,
    end_station_name,
    start_lat,
    start_lon,
    end_lat,
    end_lon
  ORDER BY
    trip_count DESC
  LIMIT
    20
),
taxi_trips AS (
  SELECT
    ROUND(pickup_latitude, 3) AS pickup_lat,
    ROUND(pickup_longitude, 3) AS pickup_lon,
    ROUND(dropoff_latitude, 3) AS dropoff_lat,
    ROUND(dropoff_longitude, 3) AS dropoff_lon,
    ROUND(AVG((UNIX_SECONDS(dropoff_datetime) - UNIX_SECONDS(pickup_datetime)) / 60), 4) AS avg_taxi_duration_minutes
  FROM
    `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE
    EXTRACT(YEAR FROM pickup_datetime) = 2016
    AND pickup_latitude IS NOT NULL
    AND pickup_longitude IS NOT NULL
    AND dropoff_latitude IS NOT NULL
    AND dropoff_longitude IS NOT NULL
  GROUP BY
    pickup_lat,
    pickup_lon,
    dropoff_lat,
    dropoff_lon
)
SELECT
  tr.start_station_name
FROM
  top_routes tr
JOIN
  taxi_trips tt
ON
  tr.start_lat = tt.pickup_lat
  AND tr.start_lon = tt.pickup_lon
  AND tr.end_lat = tt.dropoff_lat
  AND tr.end_lon = tt.dropoff_lon
WHERE
  tr.avg_bike_duration_minutes < tt.avg_taxi_duration_minutes
ORDER BY
  tr.avg_bike_duration_minutes DESC
LIMIT
  1;