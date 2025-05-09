WITH bike_2016 AS (
  -- every 2016 Citi Bike route rounded to 3-decimals
  SELECT
    ROUND(start_station_latitude ,3) AS s_lat3,
    ROUND(start_station_longitude,3) AS s_lon3,
    ROUND(end_station_latitude   ,3) AS e_lat3,
    ROUND(end_station_longitude  ,3) AS e_lon3,
    ANY_VALUE(start_station_name)    AS start_station_name,
    COUNT(*)                         AS trips,
    AVG(tripduration)               AS avg_bike_sec
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
  GROUP BY 1,2,3,4
),
top20 AS (                 -- 20 most-frequent Citi Bike routes
  SELECT *
  FROM bike_2016
  ORDER BY trips DESC
  LIMIT 20
),
taxi_2016 AS (
  -- yellow-taxi trips, same 3-dec rounding, with average duration
  SELECT
    ROUND(pickup_latitude ,3)  AS s_lat3,
    ROUND(pickup_longitude,3)  AS s_lon3,
    ROUND(dropoff_latitude,3)  AS e_lat3,
    ROUND(dropoff_longitude,3) AS e_lon3,
    AVG(
      TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)
    ) AS avg_taxi_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime  IS NOT NULL
    AND dropoff_datetime IS NOT NULL
    AND pickup_latitude  IS NOT NULL
    AND pickup_longitude IS NOT NULL
    AND dropoff_latitude IS NOT NULL
    AND dropoff_longitude IS NOT NULL
  GROUP BY 1,2,3,4
),
bike_vs_taxi AS (          -- keep routes where bikes beat taxis
  SELECT
    b.start_station_name,
    b.avg_bike_sec,
    t.avg_taxi_sec
  FROM top20 b
  JOIN taxi_2016 t
  USING (s_lat3, s_lon3, e_lat3, e_lon3)
  WHERE b.avg_bike_sec < t.avg_taxi_sec
),
ranked AS (                -- rank by (still slow) bike duration
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY avg_bike_sec DESC) AS rn
  FROM bike_vs_taxi
)
-- start-station name of the bike-faster route
-- that still has the longest average bike duration
SELECT start_station_name
FROM ranked
WHERE rn = 1;