WITH top_station AS (
  SELECT
    start_station_id,
    COUNT(*) AS trip_count
  FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE
    EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY
    start_station_id
  ORDER BY
    trip_count DESC
  LIMIT 1
),
peak_stats AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS Peak_day_of_week,
    EXTRACT(HOUR FROM starttime) AS Peak_hour,
    COUNT(*) AS trip_count
  FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE
    start_station_id = (SELECT start_station_id FROM top_station)
    AND EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY
    Peak_day_of_week, Peak_hour
  ORDER BY
    trip_count DESC
  LIMIT 1
)
SELECT
  Peak_day_of_week,
  Peak_hour
FROM
  peak_stats;