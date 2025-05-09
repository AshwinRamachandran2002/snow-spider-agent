/*  Start-station name of the 2016 top-20 Citi Bike route that
    is faster than yellow taxis yet still has the longest
    average bike duration (coordinates rounded to 3 decimals). */
WITH top20 AS (      -- 1. twenty most-used bike routes in 2016
  SELECT start_station_id,
         end_station_id,
         COUNT(*) AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY start_station_id, end_station_id
  ORDER BY trips DESC
  LIMIT 20
),
bike AS (             -- 2. average bike time & rounded coords
  SELECT
    t.start_station_id,
    t.end_station_id,
    ROUND(s1.latitude ,3) AS p_lat3,
    ROUND(s1.longitude,3) AS p_lon3,
    ROUND(s2.latitude ,3) AS d_lat3,
    ROUND(s2.longitude,3) AS d_lon3,
    AVG(t.tripduration)   AS avg_bike_sec
  FROM `bigquery-public-data.new_york.citibike_trips` AS t
  JOIN top20 USING (start_station_id, end_station_id)
  JOIN `bigquery-public-data.new_york.citibike_stations` AS s1
    ON SAFE_CAST(s1.station_id AS INT64) = t.start_station_id
  JOIN `bigquery-public-data.new_york.citibike_stations` AS s2
    ON SAFE_CAST(s2.station_id AS INT64) = t.end_station_id
  WHERE EXTRACT(YEAR FROM t.starttime) = 2016
  GROUP BY start_station_id, end_station_id,
           p_lat3, p_lon3, d_lat3, d_lon3
),
taxi AS (             -- 3. yellow-taxi averages between same rounded pairs
  SELECT
    ROUND(pickup_latitude ,3)  AS p_lat3,
    ROUND(pickup_longitude,3)  AS p_lon3,
    ROUND(dropoff_latitude ,3) AS d_lat3,
    ROUND(dropoff_longitude,3) AS d_lon3,
    AVG(TIMESTAMP_DIFF(dropoff_datetime,
                       pickup_datetime,SECOND)) AS avg_taxi_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime < dropoff_datetime
    AND pickup_latitude  IS NOT NULL
    AND dropoff_latitude IS NOT NULL
  GROUP BY p_lat3, p_lon3, d_lat3, d_lon3
),
faster AS (           -- 4. keep routes where bikes beat taxis
  SELECT b.*
  FROM bike b
  JOIN taxi t
    ON b.p_lat3 = t.p_lat3
   AND b.p_lon3 = t.p_lon3
   AND b.d_lat3 = t.d_lat3
   AND b.d_lon3 = t.d_lon3
  WHERE b.avg_bike_sec < t.avg_taxi_sec
),
winner AS (           -- 5. longest bike time among faster routes
  SELECT *
  FROM faster
  ORDER BY avg_bike_sec DESC
  LIMIT 1
)
SELECT
  s.name AS start_station_name
FROM winner w
JOIN `bigquery-public-data.new_york.citibike_stations` AS s
  ON SAFE_CAST(s.station_id AS INT64) = w.start_station_id;