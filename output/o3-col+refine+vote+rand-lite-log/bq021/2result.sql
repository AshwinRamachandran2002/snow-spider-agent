-- Start-station name of the 2016 Citi Bike route that
--   • ranks in the 20 most-frequent bike routes,
--   • is faster on average than yellow taxis for the same 3-dec-rounded route, and
--   • has the longest average bike time among those faster-than-taxi routes
WITH bike_top20 AS (
  SELECT
    CONCAT(
      CAST(ROUND(start_station_latitude ,3) AS STRING),'|',
      CAST(ROUND(start_station_longitude,3) AS STRING),'|',
      CAST(ROUND(end_station_latitude   ,3) AS STRING),'|',
      CAST(ROUND(end_station_longitude  ,3) AS STRING)
    )                AS route_key,
    COUNT(*)         AS bike_trips,
    AVG(tripduration)AS avg_bike_secs
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
  GROUP BY route_key
  ORDER BY bike_trips DESC
  LIMIT 20
),
taxi16 AS (
  SELECT
    CONCAT(
      CAST(ROUND(pickup_latitude ,3) AS STRING),'|',
      CAST(ROUND(pickup_longitude,3) AS STRING),'|',
      CAST(ROUND(dropoff_latitude,3) AS STRING),'|',
      CAST(ROUND(dropoff_longitude,3) AS STRING)
    ) AS route_key,
    AVG(
      UNIX_SECONDS(dropoff_datetime) - UNIX_SECONDS(pickup_datetime)
    ) AS avg_taxi_secs
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime BETWEEN '2016-01-01' AND '2016-12-31'
    AND dropoff_datetime IS NOT NULL
    AND pickup_latitude  IS NOT NULL
    AND dropoff_latitude IS NOT NULL
  GROUP BY route_key
),
faster AS (
  SELECT b.route_key, b.avg_bike_secs
  FROM bike_top20 b
  JOIN taxi16     t USING (route_key)
  WHERE b.avg_bike_secs < t.avg_taxi_secs          -- bikes faster than taxis
),
winner AS (
  SELECT route_key
  FROM faster
  ORDER BY avg_bike_secs DESC                      -- longest avg bike time
  LIMIT 1
)
SELECT DISTINCT start_station_name
FROM `bigquery-public-data.new_york.citibike_trips`
WHERE EXTRACT(YEAR FROM starttime)=2016
  AND CONCAT(
        CAST(ROUND(start_station_latitude ,3) AS STRING),'|',
        CAST(ROUND(start_station_longitude,3) AS STRING),'|',
        CAST(ROUND(end_station_latitude   ,3) AS STRING),'|',
        CAST(ROUND(end_station_longitude  ,3) AS STRING)
      ) = (SELECT route_key FROM winner);