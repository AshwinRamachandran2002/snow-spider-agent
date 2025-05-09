WITH most_popular_station AS (
  SELECT
    start_station_id
  FROM (
    SELECT
      start_station_id,
      COUNT(*) AS trip_count
    FROM
      `bigquery-public-data.new_york_citibike.citibike_trips`
    WHERE
      EXTRACT(YEAR FROM starttime) = 2018
      AND start_station_id IS NOT NULL
    GROUP BY
      start_station_id
    ORDER BY
      trip_count DESC
    LIMIT
      1
  )
)

SELECT
  EXTRACT(DAYOFWEEK FROM starttime) AS Peak_day_of_week,
  EXTRACT(HOUR FROM starttime) AS Peak_hour
FROM
  `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
  EXTRACT(YEAR FROM starttime) = 2018
  AND start_station_id = (SELECT start_station_id FROM most_popular_station)
GROUP BY
  Peak_day_of_week,
  Peak_hour
ORDER BY
  COUNT(*) DESC
LIMIT
  1;