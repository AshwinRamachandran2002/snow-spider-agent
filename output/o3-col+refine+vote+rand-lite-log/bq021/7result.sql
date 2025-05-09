--  Start–station name of the busiest-20 Citi Bike routes (2016)
--  on which bikes beat yellow taxis, selecting the one whose
--  average bike ride takes the longest.
WITH bike AS (
  SELECT
      ROUND(start_station_latitude ,3) AS o_lat,
      ROUND(start_station_longitude,3) AS o_lon,
      ROUND(end_station_latitude   ,3) AS d_lat,
      ROUND(end_station_longitude  ,3) AS d_lon,
      COUNT(*)                       AS rides,
      AVG(tripduration/60.0)         AS bike_avg_min,
      ANY_VALUE(start_station_name)  AS start_name
  FROM   `bigquery-public-data.new_york.citibike_trips`
  WHERE  EXTRACT(YEAR FROM starttime)=2016
  GROUP  BY o_lat, o_lon, d_lat, d_lon
),
top20 AS (
  SELECT *
  FROM   bike
  ORDER  BY rides DESC
  LIMIT  20
),
taxi AS (
  SELECT
      ROUND(pickup_latitude ,3) AS o_lat,
      ROUND(pickup_longitude,3) AS o_lon,
      ROUND(dropoff_latitude,3) AS d_lat,
      ROUND(dropoff_longitude,3) AS d_lon,
      AVG(TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND)/60.0) AS taxi_avg_min
  FROM   `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE  pickup_datetime IS NOT NULL
    AND  dropoff_datetime IS NOT NULL
    AND  pickup_longitude  IS NOT NULL
    AND  dropoff_longitude IS NOT NULL
  GROUP  BY o_lat, o_lon, d_lat, d_lon
),
faster AS (
  SELECT t.*, tx.taxi_avg_min
  FROM   top20 AS t
  JOIN   taxi  AS tx
  USING  (o_lat, o_lon, d_lat, d_lon)
  WHERE  t.bike_avg_min < tx.taxi_avg_min   -- bike faster than taxi
)
SELECT
  start_name AS fastest_but_long_bike_route_start_station
FROM   faster
ORDER  BY bike_avg_min DESC          -- longest bike duration among the faster ones
LIMIT  1;