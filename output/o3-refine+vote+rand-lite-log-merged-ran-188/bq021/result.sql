WITH bike_routes AS (
  /* Build every 2016 Citi Bike route, rounding coordinates to 3 decimals */
  SELECT
    ROUND(start_station_latitude ,3) AS s_lat ,
    ROUND(start_station_longitude,3) AS s_lon ,
    ROUND(end_station_latitude   ,3) AS e_lat ,
    ROUND(end_station_longitude  ,3) AS e_lon ,
    ANY_VALUE(start_station_name)    AS start_station_name ,      -- representative name
    COUNT(*)                           AS bike_trips ,
    AVG(tripduration)                  AS bike_avg_sec            -- average bike time (s)
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
        AND start_station_latitude  IS NOT NULL
        AND start_station_longitude IS NOT NULL
        AND end_station_latitude    IS NOT NULL
        AND end_station_longitude   IS NOT NULL
  GROUP BY s_lat,s_lon,e_lat,e_lon
),
top20 AS (
  /* 20 most–used Citi Bike routes in 2016 */
  SELECT *
  FROM bike_routes
  ORDER BY bike_trips DESC
  LIMIT 20
),
taxi_routes AS (
  /* Average 2016 yellow‑taxi travel time for the same rounded routes */
  SELECT
    ROUND(pickup_latitude ,3) AS s_lat ,
    ROUND(pickup_longitude,3) AS s_lon ,
    ROUND(dropoff_latitude,3) AS e_lat ,
    ROUND(dropoff_longitude,3) AS e_lon ,
    AVG(TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND)) AS taxi_avg_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_latitude  IS NOT NULL  AND pickup_latitude  != 0
    AND pickup_longitude IS NOT NULL  AND pickup_longitude != 0
    AND dropoff_latitude IS NOT NULL  AND dropoff_latitude != 0
    AND dropoff_longitude IS NOT NULL AND dropoff_longitude!= 0
  GROUP BY s_lat,s_lon,e_lat,e_lon
),
compare AS (
  /* Keep top‑20 routes where bikes are faster than taxis */
  SELECT
    t.* ,
    tr.taxi_avg_sec
  FROM top20 t
  JOIN taxi_routes tr
  USING (s_lat,s_lon,e_lat,e_lon)
  WHERE t.bike_avg_sec < tr.taxi_avg_sec
)
SELECT
  start_station_name
FROM compare
ORDER BY bike_avg_sec DESC        -- longest (yet still faster) average bike duration
LIMIT 1;