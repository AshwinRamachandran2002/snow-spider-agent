/*  Start-station whose 2016 Citi-Bike route (among the 20 busiest O-D pairs)
    is still FASTER than yellow taxis yet has the LONGEST average bike time.
    Latitude / longitude are matched on a 0.001-degree grid.                */

WITH
-- 1. 20 most-frequent Citi-Bike origin-destination pairs in 2016
top20 AS (
  SELECT
    start_station_id,
    end_station_id,
    COUNT(*) AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY 1,2
  ORDER BY trips DESC
  LIMIT 20
),

-- 2. Station lookup (keep ID as STRING to avoid non-numeric values)
stations AS (
  SELECT
    station_id,                       -- STRING
    name,
    ROUND(latitude ,3) AS lat3,
    ROUND(longitude,3) AS lon3
  FROM `bigquery-public-data.new_york.citibike_stations`
),

-- 3. Average bike duration (minutes) for each top-20 route
bike AS (
  SELECT
    tp.start_station_id,
    tp.end_station_id,
    s_from.name                      AS start_name,
    ROUND(AVG(t.tripduration) / 60, 2) AS bike_min,
    s_from.lat3                      AS from_lat3,
    s_from.lon3                      AS from_lon3,
    s_to.lat3                        AS to_lat3,
    s_to.lon3                        AS to_lon3
  FROM top20 tp
  JOIN `bigquery-public-data.new_york.citibike_trips` t
    ON t.start_station_id = tp.start_station_id
   AND t.end_station_id   = tp.end_station_id
   AND EXTRACT(YEAR FROM t.starttime) = 2016
  JOIN stations s_from
    ON s_from.station_id = CAST(tp.start_station_id AS STRING)
  JOIN stations s_to
    ON s_to.station_id   = CAST(tp.end_station_id   AS STRING)
  GROUP BY 1,2,3,5,6,7,8
),

-- 4. Average yellow-taxi travel time (minutes) between the same 0.001° cells
taxi AS (
  SELECT
    b.start_station_id,
    b.end_station_id,
    ROUND(
      AVG( (UNIX_SECONDS(dropoff_datetime) - UNIX_SECONDS(pickup_datetime)) / 60.0 )
    ,2) AS taxi_min
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016` t
  JOIN bike b
    ON ROUND(t.pickup_latitude ,3)  = b.from_lat3
   AND ROUND(t.pickup_longitude,3)  = b.from_lon3
   AND ROUND(t.dropoff_latitude ,3) = b.to_lat3
   AND ROUND(t.dropoff_longitude,3) = b.to_lon3
  WHERE pickup_datetime  IS NOT NULL
    AND dropoff_datetime IS NOT NULL
  GROUP BY 1,2
)

-- 5. Choose the bike-faster-than-taxi route with the longest bike time
SELECT b.start_name
FROM   bike b
JOIN   taxi USING (start_station_id, end_station_id)
WHERE  b.bike_min < taxi.taxi_min
ORDER  BY b.bike_min DESC
LIMIT 1;