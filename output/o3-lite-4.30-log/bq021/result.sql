WITH bike_2016 AS (
  SELECT
    start_station_id,
    end_station_id,
    start_station_name,
    ROUND(start_station_latitude , 3) AS s_lat3,
    ROUND(start_station_longitude, 3) AS s_lon3,
    ROUND(end_station_latitude   , 3) AS e_lat3,
    ROUND(end_station_longitude  , 3) AS e_lon3,
    tripduration
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
),
top20 AS (
  SELECT
    start_station_id,
    end_station_id,
    start_station_name,
    s_lat3, s_lon3, e_lat3, e_lon3,
    COUNT(*)          AS rides,
    AVG(tripduration) AS avg_bike_sec
  FROM bike_2016
  GROUP BY start_station_id, end_station_id, start_station_name,
           s_lat3, s_lon3, e_lat3, e_lon3
  ORDER BY rides DESC
  LIMIT 20
),
taxi_avg AS (
  SELECT
    ROUND(pickup_latitude , 3) AS s_lat3,
    ROUND(pickup_longitude, 3) AS s_lon3,
    ROUND(dropoff_latitude, 3) AS e_lat3,
    ROUND(dropoff_longitude, 3)AS e_lon3,
    AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)) AS avg_taxi_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_latitude  IS NOT NULL
    AND dropoff_latitude IS NOT NULL
    AND dropoff_datetime > pickup_datetime
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) BETWEEN 1 AND 7200
  GROUP BY s_lat3, s_lon3, e_lat3, e_lon3
)
SELECT
  t20.start_station_name
FROM top20   AS t20
JOIN taxi_avg AS tx
  ON t20.s_lat3 = tx.s_lat3
 AND t20.s_lon3 = tx.s_lon3
 AND t20.e_lat3 = tx.e_lat3
 AND t20.e_lon3 = tx.e_lon3
WHERE t20.avg_bike_sec < tx.avg_taxi_sec
ORDER BY t20.avg_bike_sec DESC
LIMIT 1;