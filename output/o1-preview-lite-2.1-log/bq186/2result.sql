SELECT
  FORMAT_TIMESTAMP('%Y-%m', `start_date`) AS `Month`,
  ROUND(ARRAY_AGG(`duration_sec` ORDER BY `start_date` ASC LIMIT 1)[OFFSET(0)] / 60.0, 4) AS `First_trip_duration_minutes`,
  ROUND(ARRAY_AGG(`duration_sec` ORDER BY `start_date` DESC LIMIT 1)[OFFSET(0)] / 60.0, 4) AS `Last_trip_duration_minutes`,
  ROUND(MAX(`duration_sec`) / 60.0, 4) AS `Highest_duration_minutes`,
  ROUND(MIN(`duration_sec`) / 60.0, 4) AS `Lowest_duration_minutes`
FROM `bigquery-public-data.san_francisco.bikeshare_trips`
GROUP BY `Month`
ORDER BY `Month`;