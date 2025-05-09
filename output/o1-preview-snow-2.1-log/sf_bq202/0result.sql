WITH trips_2016 AS (
  SELECT "start_station_id", TO_TIMESTAMP_LTZ("starttime" / 1e6) AS "start_ts"
  FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
  WHERE TO_TIMESTAMP_LTZ("starttime" / 1e6) >= '2016-01-01' AND TO_TIMESTAMP_LTZ("starttime" / 1e6) < '2017-01-01'
),
top_station AS (
  SELECT "start_station_id"
  FROM trips_2016
  GROUP BY "start_station_id"
  ORDER BY COUNT(*) DESC NULLS LAST
  LIMIT 1
),
peak_day_hour AS (
  SELECT
    DATE_PART('DAYOFWEEK', "start_ts") AS "day_of_week",
    DATE_PART('HOUR', "start_ts") AS "hour_of_day",
    COUNT(*) AS "trip_count"
  FROM trips_2016
  WHERE "start_station_id" = (SELECT "start_station_id" FROM top_station)
  GROUP BY "day_of_week", "hour_of_day"
  ORDER BY "trip_count" DESC NULLS LAST
  LIMIT 1
)
SELECT "day_of_week", "hour_of_day"
FROM peak_day_hour;