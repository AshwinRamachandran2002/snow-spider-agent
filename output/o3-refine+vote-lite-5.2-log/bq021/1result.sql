WITH stations AS (
  SELECT
    SAFE_CAST(station_id AS INT64)            AS station_id,
    name                                      AS station_name,
    ROUND(latitude ,3)                        AS lat3,
    ROUND(longitude,3)                        AS lon3
  FROM `bigquery-public-data.new_york.citibike_stations`
  WHERE latitude  IS NOT NULL
    AND longitude IS NOT NULL
    AND SAFE_CAST(station_id AS INT64) IS NOT NULL        -- keep only numeric IDs
),
/* 1. 2016 Citi Bike routes and their stats */
bike_routes_2016 AS (
  SELECT
    start_station_id,
    end_station_id,
    COUNT(*)                   AS trip_cnt,
    AVG(tripduration)          AS bike_avg_dur_sec   -- seconds
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
    AND start_station_id IS NOT NULL
    AND end_station_id   IS NOT NULL
  GROUP BY start_station_id,end_station_id
),
/* 2. top 20 most‑ridden routes */
top20 AS (
  SELECT *
  FROM bike_routes_2016
  ORDER BY trip_cnt DESC
  LIMIT 20
),
/* 3. attach rounded coordinates for those routes */
top20_geo AS (
  SELECT
    s1.station_name               AS start_station_name,
    s1.lat3                       AS start_lat3,
    s1.lon3                       AS start_lon3,
    s2.station_name               AS end_station_name,
    s2.lat3                       AS end_lat3,
    s2.lon3                       AS end_lon3,
    t.*
  FROM top20 t
  JOIN stations s1 ON s1.station_id = t.start_station_id
  JOIN stations s2 ON s2.station_id = t.end_station_id
),
/* 4. Yellow‑taxi trips in 2016 with 3‑decimal rounded coords */
taxi_2016 AS (
  SELECT
    ROUND(pickup_latitude ,3)       AS plat3,
    ROUND(pickup_longitude,3)       AS plon3,
    ROUND(dropoff_latitude ,3)      AS dlat3,
    ROUND(dropoff_longitude,3)      AS dlon3,
    TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND) AS dur_sec
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_latitude  IS NOT NULL
    AND pickup_longitude IS NOT NULL
    AND dropoff_latitude IS NOT NULL
    AND dropoff_longitude IS NOT NULL
    AND TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND) > 0
    AND pickup_latitude  BETWEEN 40 AND 41
    AND pickup_longitude BETWEEN -75 AND -70
    AND dropoff_latitude BETWEEN 40 AND 41
    AND dropoff_longitude BETWEEN -75 AND -70
),
taxi_route_avg AS (
  SELECT
    plat3, plon3, dlat3, dlon3,
    AVG(dur_sec) AS taxi_avg_dur_sec
  FROM taxi_2016
  GROUP BY plat3, plon3, dlat3, dlon3
),
/* 5. compare: keep routes where bikes are faster */
bike_vs_taxi AS (
  SELECT
    g.start_station_name,
    g.bike_avg_dur_sec,
    tr.taxi_avg_dur_sec
  FROM top20_geo g
  JOIN taxi_route_avg tr
    ON g.start_lat3 = tr.plat3  AND g.start_lon3 = tr.plon3
   AND g.end_lat3   = tr.dlat3  AND g.end_lon3   = tr.dlon3
  WHERE g.bike_avg_dur_sec < tr.taxi_avg_dur_sec
)
/* 6. fastest‑than‑taxi route that still has the longest bike duration */
SELECT start_station_name
FROM bike_vs_taxi
ORDER BY bike_avg_dur_sec DESC
LIMIT 1;