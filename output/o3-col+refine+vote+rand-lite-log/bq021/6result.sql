WITH bike_routes AS (
  -- Top-20 Citi Bike routes of 2016 (3-dec rounded coordinates)
  SELECT
    ROUND(start_station_latitude, 3)  AS start_lat3,
    ROUND(start_station_longitude, 3) AS start_lon3,
    ROUND(end_station_latitude,   3)  AS end_lat3,
    ROUND(end_station_longitude,  3)  AS end_lon3,
    ANY_VALUE(start_station_name)     AS start_station_name,
    COUNT(*)                          AS bike_trips,
    AVG(tripduration)                 AS avg_bike_secs
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY 1,2,3,4
  ORDER BY bike_trips DESC
  LIMIT 20
),
taxi_routes AS (
  -- Average yellow-taxi time for the same 3-dec routes in 2016
  SELECT
    ROUND(pickup_latitude,  3) AS start_lat3,
    ROUND(pickup_longitude, 3) AS start_lon3,
    ROUND(dropoff_latitude, 3) AS end_lat3,
    ROUND(dropoff_longitude,3) AS end_lon3,
    AVG(
      TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)
    ) AS avg_taxi_secs
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE dropoff_datetime IS NOT NULL
    AND pickup_latitude  IS NOT NULL
    AND dropoff_latitude IS NOT NULL
  GROUP BY 1,2,3,4
)
-- Pick the (bike faster than taxi) route that still has the longest avg bike time
SELECT
  b.start_station_name
FROM bike_routes b
JOIN taxi_routes t
USING (start_lat3, start_lon3, end_lat3, end_lon3)
WHERE b.avg_bike_secs < t.avg_taxi_secs          -- bikes beat taxis
ORDER BY b.avg_bike_secs DESC                    -- longest of the faster ones
LIMIT 1;