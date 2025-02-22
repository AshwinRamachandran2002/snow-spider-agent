-- Task: For the top 20 Citi Bike routes in 2016, which route has the longest average bike duration? Please provide the start station name of this route.

WITH citibike_2016 AS (
  SELECT 
    "tripduration",
    "starttime",
    "start_station_name",
    ROUND("start_station_latitude", 3) AS "start_latitude",
    ROUND("start_station_longitude", 3) AS "start_longitude",
    ROUND("end_station_latitude", 3) AS "end_latitude",
    ROUND("end_station_longitude", 3) AS "end_longitude"
  FROM "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
  WHERE YEAR(TO_TIMESTAMP_LTZ("starttime" / 1e6)) = 2016
),
bike_routes AS (
  SELECT
    "start_latitude",
    "start_longitude",
    "end_latitude",
    "end_longitude",
    "start_station_name",
    COUNT(*) AS "trip_count",
    AVG("tripduration") AS "avg_bike_duration"
  FROM citibike_2016
  GROUP BY 
    "start_latitude", 
    "start_longitude", 
    "end_latitude", 
    "end_longitude", 
    "start_station_name"
),
top_bike_routes AS (
  SELECT
    *
  FROM bike_routes
  ORDER BY "trip_count" DESC NULLS LAST
  LIMIT 20
)
SELECT "start_station_name"
FROM top_bike_routes
ORDER BY "avg_bike_duration" DESC NULLS LAST
LIMIT 1;