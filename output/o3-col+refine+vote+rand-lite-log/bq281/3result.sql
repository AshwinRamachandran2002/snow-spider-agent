SELECT
  MAX(rides) AS max_daily_rides
FROM (
  SELECT
    DATE(`start_time`) AS ride_date,
    COUNT(*)           AS rides
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE `bike_type` = 'electric'
    AND `subscriber_type` = 'Student Membership'
    AND `duration_minutes` > 10
    AND LOWER(`start_station_name`) NOT LIKE '%mobile station%'
    AND LOWER(`end_station_name`)   NOT LIKE '%mobile station%'
    AND LOWER(`start_station_name`) NOT LIKE '%repair shop%'
    AND LOWER(`end_station_name`)   NOT LIKE '%repair shop%'
  GROUP BY ride_date
);