SELECT
  MAX(daily_count) AS highest_daily_count
FROM (
  SELECT
    DATE(`start_time`) AS ride_date,
    COUNT(*)           AS daily_count
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
    LOWER(`bike_type`) = 'electric'
    AND `duration_minutes`  > 10
    AND `subscriber_type`   = 'Student Membership'
    AND LOWER(`start_station_name`) NOT LIKE '%mobile station%'
    AND LOWER(`end_station_name`)   NOT LIKE '%mobile station%'
    AND LOWER(`start_station_name`) NOT LIKE '%repair shop%'
    AND LOWER(`end_station_name`)   NOT LIKE '%repair shop%'
  GROUP BY
    ride_date
);