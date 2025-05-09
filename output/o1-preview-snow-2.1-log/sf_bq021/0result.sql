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
  GROUP BY "start_latitude", "start_longitude", "end_latitude", "end_longitude", "start_station_name"
),
top_bike_routes AS (
  SELECT
    *
  FROM bike_routes
  ORDER BY "trip_count" DESC NULLS LAST
  LIMIT 20
),
taxi_2016 AS (
  SELECT
    (("dropoff_datetime" - "pickup_datetime") / 1e6) AS "taxi_tripduration",
    ROUND("pickup_latitude", 3) AS "start_latitude",
    ROUND("pickup_longitude", 3) AS "start_longitude",
    ROUND("dropoff_latitude", 3) AS "end_latitude",
    ROUND("dropoff_longitude", 3) AS "end_longitude"
  FROM "NEW_YORK"."NEW_YORK"."TLC_YELLOW_TRIPS_2016"
  WHERE YEAR(TO_TIMESTAMP_LTZ("pickup_datetime" / 1e6)) = 2016
    AND "pickup_latitude" IS NOT NULL
    AND "pickup_longitude" IS NOT NULL
    AND "dropoff_latitude" IS NOT NULL
    AND "dropoff_longitude" IS NOT NULL
    AND "pickup_datetime" IS NOT NULL
    AND "dropoff_datetime" IS NOT NULL
    AND ("dropoff_datetime" - "pickup_datetime") > 0
),
taxi_routes AS (
  SELECT
    "start_latitude",
    "start_longitude",
    "end_latitude",
    "end_longitude",
    AVG("taxi_tripduration") AS "avg_taxi_duration"
  FROM taxi_2016
  GROUP BY "start_latitude", "start_longitude", "end_latitude", "end_longitude"
),
joined_routes AS (
  SELECT
    b."start_latitude",
    b."start_longitude",
    b."end_latitude",
    b."end_longitude",
    b."start_station_name",
    b."trip_count",
    b."avg_bike_duration",
    t."avg_taxi_duration"
  FROM top_bike_routes b
  INNER JOIN taxi_routes t
  ON b."start_latitude" = t."start_latitude"
     AND b."start_longitude" = t."start_longitude"
     AND b."end_latitude" = t."end_latitude"
     AND b."end_longitude" = t."end_longitude"
)
SELECT "start_station_name"
FROM joined_routes
WHERE "avg_bike_duration" < "avg_taxi_duration"
ORDER BY "avg_bike_duration" DESC NULLS LAST
LIMIT 1;