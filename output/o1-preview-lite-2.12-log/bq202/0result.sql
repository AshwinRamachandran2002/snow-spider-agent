WITH trips AS (
  SELECT 
    start_station_id,
    starttime
  FROM 
    `bigquery-public-data.new_york.citibike_trips`
  WHERE 
    EXTRACT(YEAR FROM starttime) = 2015
),

busiest_station AS (
  SELECT
    start_station_id
  FROM
    trips
  GROUP BY
    start_station_id
  ORDER BY
    COUNT(*) DESC
  LIMIT 1
),

trips_busiest_station AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS day_of_week,
    EXTRACT(HOUR FROM starttime) AS hour_of_day,
    COUNT(*) AS trip_count
  FROM
    trips
  WHERE
    start_station_id = (SELECT start_station_id FROM busiest_station)
  GROUP BY
    day_of_week,
    hour_of_day
)

SELECT
  day_of_week,
  hour_of_day
FROM
  trips_busiest_station
ORDER BY
  trip_count DESC
LIMIT 1;