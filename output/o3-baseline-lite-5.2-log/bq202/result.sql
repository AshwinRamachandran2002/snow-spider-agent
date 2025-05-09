WITH trips_2018 AS (
  SELECT
    start_station_id,
    starttime
  FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE
    EXTRACT(YEAR FROM starttime) = 2018
    AND start_station_id IS NOT NULL
),
top_start_station AS (
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
top_station_trips AS (
  SELECT
    t.starttime
  FROM
    trips_2018 t
  JOIN
    top_start_station s
  USING (start_station_id)
)
SELECT
  EXTRACT(DAYOFWEEK FROM starttime) AS day_of_week,   -- 1 = Sunday … 7 = Saturday
  EXTRACT(HOUR FROM starttime)      AS hour_of_day    -- 0‑23
FROM
  top_station_trips
GROUP BY
  day_of_week,
  hour_of_day
ORDER BY
  COUNT(*) DESC
LIMIT 1;