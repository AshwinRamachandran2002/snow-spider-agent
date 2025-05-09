WITH cb_2016 AS (   -- Citi Bike trips in 2016
  SELECT
    ROUND(start_station_latitude ,3) AS start_lat3,
    ROUND(start_station_longitude,3) AS start_lon3,
    ROUND(end_station_latitude   ,3) AS end_lat3,
    ROUND(end_station_longitude  ,3) AS end_lon3,
    start_station_name,
    end_station_name,
    tripduration
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
        AND start_station_latitude  IS NOT NULL
        AND start_station_longitude IS NOT NULL
        AND end_station_latitude    IS NOT NULL
        AND end_station_longitude   IS NOT NULL
),
top_routes AS (     -- 20 most–frequent Citi Bike routes
  SELECT
    start_lat3, start_lon3, end_lat3, end_lon3,
    ANY_VALUE(start_station_name) AS start_station_name,
    ANY_VALUE(end_station_name)   AS end_station_name,
    COUNT(*)                     AS trip_cnt,
    AVG(tripduration)            AS bike_avg_dur   -- seconds
  FROM cb_2016
  GROUP BY start_lat3, start_lon3, end_lat3, end_lon3
  ORDER BY trip_cnt DESC
  LIMIT 20
),
taxi_durations AS ( -- Yellow‑taxi average durations for same rounded coords
  SELECT
    ROUND(pickup_latitude ,3) AS start_lat3,
    ROUND(pickup_longitude,3) AS start_lon3,
    ROUND(dropoff_latitude ,3) AS end_lat3,
    ROUND(dropoff_longitude,3) AS end_lon3,
    AVG( TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) ) AS taxi_avg_dur
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_latitude  BETWEEN 40 AND 41
        AND dropoff_latitude BETWEEN 40 AND 41
        AND pickup_longitude BETWEEN -75 AND -73
        AND dropoff_longitude BETWEEN -75 AND -73
        AND pickup_latitude  IS NOT NULL AND dropoff_latitude  IS NOT NULL
        AND pickup_longitude IS NOT NULL AND dropoff_longitude IS NOT NULL
        AND pickup_latitude  != 0   AND dropoff_latitude  != 0
        AND pickup_longitude != 0   AND dropoff_longitude != 0
  GROUP BY start_lat3, start_lon3, end_lat3, end_lon3
),
faster_than_taxi AS (   -- routes where bikes beat taxis
  SELECT
    r.*,
    d.taxi_avg_dur
  FROM top_routes r
  JOIN taxi_durations d
    USING (start_lat3, start_lon3, end_lat3, end_lon3)
  WHERE r.bike_avg_dur < d.taxi_avg_dur
)
-- among those routes choose the one whose (still‑faster) bikes take the longest
SELECT
  start_station_name
FROM faster_than_taxi
ORDER BY bike_avg_dur DESC
LIMIT 1;