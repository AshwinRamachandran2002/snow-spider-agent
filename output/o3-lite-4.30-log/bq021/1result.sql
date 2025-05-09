WITH bike_routes AS (
  SELECT
    ROUND(start_station_latitude ,3) AS o_lat,
    ROUND(start_station_longitude,3) AS o_lon,
    ROUND(end_station_latitude   ,3) AS d_lat,
    ROUND(end_station_longitude  ,3) AS d_lon,
    ANY_VALUE(start_station_name)     AS start_station_name,
    COUNT(*)                         AS rides,
    AVG(tripduration)                AS avg_bike_sec
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
  GROUP BY o_lat,o_lon,d_lat,d_lon
),
top20 AS (
  SELECT *
  FROM bike_routes
  ORDER BY rides DESC
  LIMIT 20
),
taxi_routes AS (
  SELECT
    ROUND(pickup_latitude ,3)  AS o_lat,
    ROUND(pickup_longitude,3)  AS o_lon,
    ROUND(dropoff_latitude,3)  AS d_lat,
    ROUND(dropoff_longitude,3) AS d_lon,
    AVG(TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND)) AS avg_taxi_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime >= '2016-01-01' AND pickup_datetime < '2017-01-01'
    AND pickup_latitude  BETWEEN 40 AND 41   AND dropoff_latitude  BETWEEN 40 AND 41
    AND pickup_longitude BETWEEN -75 AND -73 AND dropoff_longitude BETWEEN -75 AND -73
    AND pickup_latitude  IS NOT NULL         AND dropoff_latitude  IS NOT NULL
    AND pickup_latitude  <> 0                AND dropoff_latitude <> 0
  GROUP BY o_lat,o_lon,d_lat,d_lon
),
faster_routes AS (
  SELECT
    t.*,
    tx.avg_taxi_sec
  FROM top20 t
  JOIN taxi_routes tx USING (o_lat,o_lon,d_lat,d_lon)
  WHERE t.avg_bike_sec < tx.avg_taxi_sec          -- bike faster than taxi
),
chosen AS (
  SELECT *
  FROM faster_routes
  ORDER BY avg_bike_sec DESC                       -- longest avg bike duration among faster ones
  LIMIT 1
)
SELECT
  start_station_name,
  FORMAT('%0.3f,%0.3f->%0.3f,%0.3f', o_lat, o_lon, d_lat, d_lon)          AS travel_coordinates,
  ROUND(ST_DISTANCE(ST_GEOGPOINT(o_lon, o_lat), ST_GEOGPOINT(d_lon, d_lat)) / 1000 * rides, 4) AS cumulative_travel_distance
FROM chosen;