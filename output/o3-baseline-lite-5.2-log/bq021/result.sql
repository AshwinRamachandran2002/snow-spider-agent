WITH bike_routes AS (
  -- Citi Bike routes in 2016
  SELECT
    start_station_id,
    end_station_id,
    ANY_VALUE(start_station_name)          AS start_station_name,
    -- origin / destination rounded to 3 decimals
    ROUND(ANY_VALUE(start_station_latitude) ,3)  AS start_lat_3,
    ROUND(ANY_VALUE(start_station_longitude),3)  AS start_lon_3,
    ROUND(ANY_VALUE(end_station_latitude)   ,3)  AS end_lat_3,
    ROUND(ANY_VALUE(end_station_longitude)  ,3)  AS end_lon_3,
    COUNT(*)                               AS trip_cnt,
    AVG(tripduration)                      AS avg_bike_secs          -- seconds
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
  GROUP BY start_station_id, end_station_id
),
top20 AS (                       -- 20 busiest bike routes
  SELECT *
  FROM bike_routes
  ORDER BY trip_cnt DESC
  LIMIT 20
),
taxi_routes AS (                 -- Yellow‑taxi routes in 2016 (same 3‑dec coords)
  SELECT
    ROUND(pickup_latitude ,3) AS start_lat_3,
    ROUND(pickup_longitude,3) AS start_lon_3,
    ROUND(dropoff_latitude ,3) AS end_lat_3,
    ROUND(dropoff_longitude,3) AS end_lon_3,
    AVG(TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND)) AS avg_taxi_secs
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_latitude  IS NOT NULL AND pickup_longitude  IS NOT NULL
    AND dropoff_latitude IS NOT NULL AND dropoff_longitude IS NOT NULL
    AND pickup_latitude  <> 0       AND pickup_longitude  <> 0
    AND dropoff_latitude <> 0       AND dropoff_longitude <> 0
  GROUP BY start_lat_3,start_lon_3,end_lat_3,end_lon_3
),
faster_than_taxi AS (            -- bike routes whose mean time < taxi mean time
  SELECT
    t.start_station_name,
    t.avg_bike_secs
  FROM top20 t
  JOIN taxi_routes x
    ON  t.start_lat_3 = x.start_lat_3
    AND t.start_lon_3 = x.start_lon_3
    AND t.end_lat_3   = x.end_lat_3
    AND t.end_lon_3   = x.end_lon_3
  WHERE t.avg_bike_secs < x.avg_taxi_secs
)
SELECT start_station_name
FROM faster_than_taxi
ORDER BY avg_bike_secs DESC      -- longest average bike time among the faster ones
LIMIT 1;