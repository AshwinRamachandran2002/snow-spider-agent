-- Task: Provide the trip ID, duration in seconds, start date, start station name, and end station name for the top 5 longest bike share trips that started between July 1, 2017, and December 31, 2017.
SELECT
  "trip_id",
  "duration_sec",
  DATE(TO_TIMESTAMP_LTZ("start_date" / 1000000)) AS "start_date",  -- Convert microseconds to date
  "start_station_name",
  "end_station_name"
FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS"
WHERE TO_TIMESTAMP_LTZ("start_date" / 1000000) BETWEEN '2017-07-01' AND '2017-12-31'
ORDER BY "duration_sec" DESC
LIMIT 5;