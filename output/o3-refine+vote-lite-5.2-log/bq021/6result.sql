WITH bike_2016 AS (
  SELECT
    start_station_id,
    end_station_id,
    start_station_name,
    end_station_name,
    start_station_latitude  AS start_lat,
    start_station_longitude AS start_lon,
    end_station_latitude    AS end_lat,
    end_station_longitude   AS end_lon,
    tripduration
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
    AND start_station_id IS NOT NULL
    AND end_station_id   IS NOT NULL
),
route_counts AS (
  SELECT
    start_station_id,
    end_station_id,
    start_station_name,
    end_station_name,
    ANY_VALUE(start_lat) AS start_lat,
    ANY_VALUE(start_lon) AS start_lon,
    ANY_VALUE(end_lat)   AS end_lat,
    ANY_VALUE(end_lon)   AS end_lon,
    COUNT(*)             AS trip_cnt
  FROM bike_2016
  GROUP BY
    start_station_id, end_station_id,
    start_station_name, end_station_name
),
top_routes AS (
  SELECT *
  FROM route_counts
  ORDER BY trip_cnt DESC
  LIMIT 20
),
bike_stats AS (
  SELECT
    r.start_station_id,
    r.end_station_id,
    r.start_station_name,
    r.end_station_name,
    r.start_lat,
    r.start_lon,
    r.end_lat,
    r.end_lon,
    AVG(b.tripduration) AS avg_bike_sec
  FROM top_routes r
  JOIN bike_2016 b
    ON b.start_station_id = r.start_station_id
   AND b.end_station_id   = r.end_station_id
  GROUP BY
    r.start_station_id, r.end_station_id,
    r.start_station_name, r.end_station_name,
    r.start_lat, r.start_lon, r.end_lat, r.end_lon
),
taxi_filtered AS (
  SELECT
    ROUND(pickup_latitude ,3) AS p_lat3,
    ROUND(pickup_longitude,3) AS p_lon3,
    ROUND(dropoff_latitude ,3) AS d_lat3,
    ROUND(dropoff_longitude,3) AS d_lon3,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS dur_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_latitude  IS NOT NULL
    AND pickup_longitude IS NOT NULL
    AND dropoff_latitude IS NOT NULL
    AND dropoff_longitude IS NOT NULL
    AND pickup_datetime  IS NOT NULL
    AND dropoff_datetime IS NOT NULL
),
taxi_stats AS (
  SELECT
    b.start_station_id,
    b.end_station_id,
    AVG(t.dur_sec) AS avg_taxi_sec
  FROM bike_stats b
  JOIN taxi_filtered t
    ON t.p_lat3 = ROUND(b.start_lat,3)
   AND t.p_lon3 = ROUND(b.start_lon,3)
   AND t.d_lat3 = ROUND(b.end_lat,3)
   AND t.d_lon3 = ROUND(b.end_lon,3)
  GROUP BY
    b.start_station_id, b.end_station_id
),
combined AS (
  SELECT
    b.*,
    ts.avg_taxi_sec
  FROM bike_stats b
  JOIN taxi_stats ts
    ON b.start_station_id = ts.start_station_id
   AND b.end_station_id   = ts.end_station_id
  WHERE b.avg_bike_sec < ts.avg_taxi_sec          -- bike route is faster
)
SELECT
  start_station_name
FROM combined
ORDER BY avg_bike_sec DESC                        -- longest average bike duration
LIMIT 1;