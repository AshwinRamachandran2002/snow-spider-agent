WITH bike_raw AS (
  -- Citi Bike trips in 2016
  SELECT
    ROUND(start_station_latitude ,3) AS start_lat ,
    ROUND(start_station_longitude,3) AS start_lon ,
    ROUND(end_station_latitude   ,3) AS end_lat   ,
    ROUND(end_station_longitude  ,3) AS end_lon   ,
    start_station_name,
    tripduration
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
        AND tripduration > 0
        AND start_station_latitude  IS NOT NULL
        AND start_station_longitude IS NOT NULL
        AND end_station_latitude    IS NOT NULL
        AND end_station_longitude   IS NOT NULL
),
bike_agg AS (
  -- aggregate bike routes
  SELECT
    start_lat, start_lon, end_lat, end_lon,
    ANY_VALUE(start_station_name) AS start_station_name,
    COUNT(*)                      AS bike_trip_cnt,
    AVG(tripduration)             AS bike_avg_dur_sec      -- in seconds
  FROM bike_raw
  GROUP BY start_lat, start_lon, end_lat, end_lon
),
top20_bike AS (
  -- 20 most–ridden bike routes
  SELECT *
  FROM bike_agg
  ORDER BY bike_trip_cnt DESC
  LIMIT 20
),
taxi_raw AS (
  -- yellow–taxi trips in 2016
  SELECT
    ROUND(pickup_latitude ,3)  AS start_lat ,
    ROUND(pickup_longitude,3)  AS start_lon ,
    ROUND(dropoff_latitude,3)  AS end_lat   ,
    ROUND(dropoff_longitude,3) AS end_lon   ,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS dur_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_latitude   IS NOT NULL
        AND pickup_longitude  IS NOT NULL
        AND dropoff_latitude  IS NOT NULL
        AND dropoff_longitude IS NOT NULL
),
taxi_agg AS (
  -- aggregate taxi routes
  SELECT
    start_lat, start_lon, end_lat, end_lon,
    AVG(dur_sec) AS taxi_avg_dur_sec
  FROM taxi_raw
  WHERE dur_sec > 0
  GROUP BY start_lat, start_lon, end_lat, end_lon
),
candidate AS (
  -- bike routes that are faster (shorter average duration) than taxis
  SELECT
    b.start_station_name,
    b.bike_avg_dur_sec,
    t.taxi_avg_dur_sec
  FROM top20_bike b
  JOIN taxi_agg  t
    ON  b.start_lat = t.start_lat
    AND b.start_lon = t.start_lon
    AND b.end_lat   = t.end_lat
    AND b.end_lon   = t.end_lon
  WHERE b.bike_avg_dur_sec < t.taxi_avg_dur_sec
)
-- among the faster routes, pick the one with the longest average bike duration
SELECT
  start_station_name
FROM candidate
ORDER BY bike_avg_dur_sec DESC
LIMIT 1;