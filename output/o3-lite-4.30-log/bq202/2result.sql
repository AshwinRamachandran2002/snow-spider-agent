WITH busiest_station AS (
  SELECT start_station_id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
dow_hr_counts AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM t.starttime) AS day_of_week,
    EXTRACT(HOUR      FROM t.starttime) AS hour_of_day,
    COUNT(*) AS trips
  FROM `bigquery-public-data.new_york_citibike.citibike_trips` AS t
  JOIN busiest_station USING (start_station_id)
  WHERE EXTRACT(YEAR FROM t.starttime) = 2018
  GROUP BY day_of_week, hour_of_day
)
SELECT
  CAST(day_of_week AS INT64) AS day_of_week,
  CAST(hour_of_day AS INT64) AS hour_of_day
FROM dow_hr_counts
ORDER BY trips DESC, day_of_week, hour_of_day
LIMIT 1;