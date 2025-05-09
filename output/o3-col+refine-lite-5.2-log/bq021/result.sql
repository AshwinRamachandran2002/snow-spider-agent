WITH bike_routes AS (        -- top‑20 Citi Bike routes of 2016
  SELECT
    ROUND(start_station_latitude ,3) AS start_lat3,
    ROUND(start_station_longitude,3) AS start_lng3,
    ROUND(end_station_latitude   ,3) AS end_lat3,
    ROUND(end_station_longitude  ,3) AS end_lng3,
    ANY_VALUE(start_station_name)    AS start_station_name,
    COUNT(*)                         AS trip_count,
    AVG(tripduration)                AS avg_bike_sec
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
  GROUP BY 1,2,3,4
  ORDER BY trip_count DESC
  LIMIT 20
),
taxi_routes AS (              -- matching yellow‑taxi grid, same year
  SELECT
    ROUND(pickup_latitude ,3) AS start_lat3,
    ROUND(pickup_longitude,3) AS start_lng3,
    ROUND(dropoff_latitude,3) AS end_lat3,
    ROUND(dropoff_longitude,3) AS end_lng3,
    AVG(TIMESTAMP_DIFF(dropoff_datetime,
                       pickup_datetime,SECOND)) AS avg_taxi_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime  IS NOT NULL
    AND dropoff_datetime IS NOT NULL
    AND pickup_latitude  IS NOT NULL
    AND pickup_longitude IS NOT NULL
    AND dropoff_latitude IS NOT NULL
    AND dropoff_longitude IS NOT NULL
  GROUP BY 1,2,3,4
)
SELECT b.start_station_name
FROM   bike_routes b
JOIN   taxi_routes t
USING  (start_lat3,start_lng3,end_lat3,end_lng3)
WHERE  b.avg_bike_sec < t.avg_taxi_sec          -- bike route is faster
ORDER BY b.avg_bike_sec DESC                    -- longest bike duration first
LIMIT 1;