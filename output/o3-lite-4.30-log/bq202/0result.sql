WITH trips_2018 AS (
  SELECT
    start_station_id,
    starttime
  FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE
    EXTRACT(YEAR FROM starttime) = 2018
),
top_station AS (
  SELECT
    start_station_id
  FROM
    trips_2018
  GROUP BY
    start_station_id
  ORDER BY
    COUNT(*) DESC
  LIMIT 1
),
day_hour_counts AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS day_of_week,
    EXTRACT(HOUR FROM starttime)      AS hour_of_day,
    COUNT(*)                          AS trips
  FROM
    trips_2018
  WHERE
    start_station_id = (SELECT start_station_id FROM top_station)
  GROUP BY
    day_of_week,
    hour_of_day
)
SELECT
  day_of_week,
  hour_of_day
FROM
  day_hour_counts
ORDER BY
  trips DESC,
  day_of_week,
  hour_of_day
LIMIT 1;