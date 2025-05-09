-- 1)  get the 20 busiest Citi‑Bike routes in 2016  
-- 2)  compute the average 2016 yellow‑taxi duration for the same
--     origin/destination (coordinates rounded to 3 decimals)  
-- 3)  keep only the routes where the bike is faster than the taxi  
-- 4)  from those, pick the one whose bikes take the longest (highest
--     average bike duration) and return its start‑station name
WITH bike_routes AS (       -- every distinct bike O‑D pair, 2016
  SELECT
    start_station_id,
    end_station_id,
    ANY_VALUE(start_station_name)             AS start_station_name,
    ROUND(start_station_latitude ,3)          AS start_lat,
    ROUND(start_station_longitude,3)          AS start_lon,
    ROUND(end_station_latitude   ,3)          AS end_lat,
    ROUND(end_station_longitude ,3)           AS end_lon,
    COUNT(*)                                  AS bike_trip_cnt,
    AVG(tripduration)                         AS avg_bike_duration   -- seconds
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE starttime >= '2016-01-01'
    AND starttime <  '2017-01-01'
    AND start_station_latitude  IS NOT NULL
    AND end_station_latitude    IS NOT NULL
  GROUP BY 1,2,4,5,6,7
),
bike_top20 AS (            -- limit to the 20 most‑used routes
  SELECT *
  FROM (
    SELECT b.*,
           ROW_NUMBER() OVER (ORDER BY bike_trip_cnt DESC) AS rn
    FROM bike_routes b )
  WHERE rn <= 20
),
taxi_agg AS (              -- average yellow‑taxi duration for same rounded coords
  SELECT
    ROUND(pickup_latitude ,3)  AS start_lat,
    ROUND(pickup_longitude,3)  AS start_lon,
    ROUND(dropoff_latitude,3)  AS end_lat,
    ROUND(dropoff_longitude,3) AS end_lon,
    AVG(TIMESTAMP_DIFF(dropoff_datetime,
                        pickup_datetime,
                        SECOND))                    AS avg_taxi_duration   -- seconds
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime  >= '2016-01-01'
    AND pickup_datetime  <  '2017-01-01'
    -- keep only valid NYC coordinates
    AND pickup_longitude  BETWEEN -80 AND -70
    AND dropoff_longitude BETWEEN -80 AND -70
    AND pickup_latitude   BETWEEN  40 AND  41
    AND dropoff_latitude  BETWEEN  40 AND  41
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) > 0
  GROUP BY 1,2,3,4
),
faster_than_taxi AS (      -- bike faster than taxi
  SELECT
    b.start_station_name,
    b.avg_bike_duration,
    t.avg_taxi_duration
  FROM bike_top20 b
  JOIN taxi_agg t
    ON b.start_lat = t.start_lat
   AND b.start_lon = t.start_lon
   AND b.end_lat   = t.end_lat
   AND b.end_lon   = t.end_lon
  WHERE b.avg_bike_duration < t.avg_taxi_duration
)
SELECT start_station_name
FROM faster_than_taxi
ORDER BY avg_bike_duration DESC   -- longest (slowest) bikes among the “faster” routes
LIMIT 1;