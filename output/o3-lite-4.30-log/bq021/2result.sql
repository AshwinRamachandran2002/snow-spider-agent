WITH top20_bike_routes AS (
  SELECT
    start_station_id,
    end_station_id,
    ANY_VALUE(start_station_name)              AS start_station_name,
    ROUND(ANY_VALUE(start_station_latitude ),3) AS pu_lat_3d,
    ROUND(ANY_VALUE(start_station_longitude),3) AS pu_lon_3d,
    ROUND(ANY_VALUE(end_station_latitude   ),3) AS do_lat_3d,
    ROUND(ANY_VALUE(end_station_longitude  ),3) AS do_lon_3d,
    AVG(tripduration) / 60.0                  AS avg_bike_min
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY start_station_id, end_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 20
),
taxi_avg AS (
  SELECT
    ROUND(pickup_latitude ,3)  AS pu_lat_3d,
    ROUND(pickup_longitude,3)  AS pu_lon_3d,
    ROUND(dropoff_latitude ,3) AS do_lat_3d,
    ROUND(dropoff_longitude,3) AS do_lon_3d,
    AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)) / 60.0
      AS avg_taxi_min
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_latitude  IS NOT NULL
    AND pickup_longitude IS NOT NULL
    AND dropoff_latitude IS NOT NULL
    AND dropoff_longitude IS NOT NULL
  GROUP BY pu_lat_3d, pu_lon_3d, do_lat_3d, do_lon_3d
)
SELECT
  b.start_station_name,
  CONCAT('(', FORMAT('%.3f', b.pu_lat_3d), ',', FORMAT('%.3f', b.pu_lon_3d),
         ')->(', FORMAT('%.3f', b.do_lat_3d), ',', FORMAT('%.3f', b.do_lon_3d), ')')
         AS travel_coordinates,
  ROUND(
    ST_DISTANCE(
      ST_GEOGPOINT(b.pu_lon_3d, b.pu_lat_3d),
      ST_GEOGPOINT(b.do_lon_3d, b.do_lat_3d)
    ) / 1000, 4)                               AS cumulative_travel_distance
FROM top20_bike_routes b
JOIN taxi_avg t
  ON  b.pu_lat_3d = t.pu_lat_3d
  AND b.pu_lon_3d = t.pu_lon_3d
  AND b.do_lat_3d = t.do_lat_3d
  AND b.do_lon_3d = t.do_lon_3d
WHERE b.avg_bike_min < t.avg_taxi_min
ORDER BY b.avg_bike_min DESC
LIMIT 1;