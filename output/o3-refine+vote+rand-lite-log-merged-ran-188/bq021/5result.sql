WITH bike_2016 AS (
  -- 2016 Citi Bike trips with coordinates rounded to three decimals
  SELECT
    ROUND(start_station_latitude ,3) AS start_lat,
    ROUND(start_station_longitude,3) AS start_lon,
    ROUND(end_station_latitude   ,3) AS end_lat,
    ROUND(end_station_longitude  ,3) AS end_lon,
    start_station_name,
    tripduration
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
),
bike_routes AS (
  -- aggregate bike routes
  SELECT
    start_lat, start_lon, end_lat, end_lon,
    ANY_VALUE(start_station_name)            AS start_station_name,
    COUNT(*)                                 AS trip_cnt,
    AVG(tripduration)                        AS avg_bike_dur
  FROM bike_2016
  GROUP BY start_lat, start_lon, end_lat, end_lon
),
top20_bike AS (
  -- 20 most–used bike routes
  SELECT *
  FROM bike_routes
  ORDER BY trip_cnt DESC
  LIMIT 20
),
taxi_2016 AS (
  -- 2016 yellow‑taxi trips with sane geo/time filters
  SELECT
    ROUND(pickup_latitude ,3)  AS start_lat,
    ROUND(pickup_longitude,3)  AS start_lon,
    ROUND(dropoff_latitude ,3) AS end_lat,
    ROUND(dropoff_longitude,3) AS end_lon,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS dur_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime BETWEEN '2016-01-01' AND '2017-01-01'
        AND pickup_latitude  BETWEEN 40   AND 41.5
        AND dropoff_latitude BETWEEN 40   AND 41.5
        AND pickup_longitude BETWEEN -74.5 AND -73
        AND dropoff_longitude BETWEEN -74.5 AND -73
        AND pickup_latitude IS NOT NULL
        AND dropoff_latitude IS NOT NULL
),
taxi_routes AS (
  -- aggregate taxi routes
  SELECT
    start_lat, start_lon, end_lat, end_lon,
    AVG(dur_sec) AS avg_taxi_dur
  FROM taxi_2016
  WHERE dur_sec > 0      -- positive duration
        AND dur_sec < 14400   -- under 4 hours to drop gross outliers
  GROUP BY start_lat, start_lon, end_lat, end_lon
),
comparison AS (
  -- join top bike routes with corresponding taxi routes
  SELECT
    b.start_station_name,
    b.avg_bike_dur,
    t.avg_taxi_dur
  FROM top20_bike b
  JOIN taxi_routes t
  USING (start_lat, start_lon, end_lat, end_lon)
  WHERE b.avg_bike_dur < t.avg_taxi_dur    -- bike faster than taxi
)
-- among the qualifying routes, take the one with the longest average bike duration
SELECT start_station_name
FROM comparison
ORDER BY avg_bike_dur DESC
LIMIT 1;