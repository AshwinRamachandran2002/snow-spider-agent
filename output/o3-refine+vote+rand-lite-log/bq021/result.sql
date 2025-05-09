WITH bike_2016 AS (
  SELECT
    start_station_id,
    end_station_id,
    start_station_name,
    end_station_name,
    ROUND(start_station_latitude ,3) AS start_lat_r,
    ROUND(start_station_longitude,3) AS start_lon_r,
    ROUND(end_station_latitude   ,3) AS end_lat_r,
    ROUND(end_station_longitude  ,3) AS end_lon_r,
    tripduration                             -- already in seconds
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
        AND start_station_latitude IS NOT NULL
        AND end_station_latitude   IS NOT NULL
),
bike_routes AS (
  SELECT
    start_station_id,
    end_station_id,
    start_station_name,
    end_station_name,
    start_lat_r, start_lon_r, end_lat_r, end_lon_r,
    COUNT(*)              AS bike_trip_count,
    AVG(tripduration)     AS avg_bike_duration          -- seconds
  FROM bike_2016
  GROUP BY
    start_station_id, end_station_id,
    start_station_name, end_station_name,
    start_lat_r, start_lon_r, end_lat_r, end_lon_r
),
top20_bike_routes AS (                       -- most–ridden Citi Bike routes in 2016
  SELECT *
  FROM bike_routes
  ORDER BY bike_trip_count DESC
  LIMIT 20
),
taxi_2016 AS (
  SELECT
    ROUND(pickup_latitude ,3)  AS start_lat_r,
    ROUND(pickup_longitude,3)  AS start_lon_r,
    ROUND(dropoff_latitude,3)  AS end_lat_r,
    ROUND(dropoff_longitude,3) AS end_lon_r,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS trip_seconds
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime  IS NOT NULL
    AND dropoff_datetime IS NOT NULL
    AND pickup_latitude  IS NOT NULL AND pickup_longitude  IS NOT NULL
    AND dropoff_latitude IS NOT NULL AND dropoff_longitude IS NOT NULL
    AND pickup_latitude  != 0      AND pickup_longitude  != 0
    AND dropoff_latitude != 0      AND dropoff_longitude != 0
),
taxi_routes AS (
  SELECT
    start_lat_r, start_lon_r, end_lat_r, end_lon_r,
    AVG(trip_seconds) AS avg_taxi_duration            -- seconds
  FROM taxi_2016
  GROUP BY
    start_lat_r, start_lon_r, end_lat_r, end_lon_r
),
faster_than_taxi AS (                           -- routes where bikes beat cabs
  SELECT
    b.*,
    t.avg_taxi_duration
  FROM top20_bike_routes b
  JOIN taxi_routes t
    ON  b.start_lat_r = t.start_lat_r
    AND b.start_lon_r = t.start_lon_r
    AND b.end_lat_r   = t.end_lat_r
    AND b.end_lon_r   = t.end_lon_r
  WHERE b.avg_bike_duration < t.avg_taxi_duration
)
SELECT
  start_station_name
FROM faster_than_taxi
ORDER BY avg_bike_duration DESC          -- longest (slowest) among the faster routes
LIMIT 1;