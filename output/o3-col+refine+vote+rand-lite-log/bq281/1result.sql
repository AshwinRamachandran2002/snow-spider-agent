SELECT
  MAX(rides_per_day) AS max_daily_student_electric_rides
FROM (
  SELECT
    DATE(`start_time`)              AS ride_date,
    COUNT(*)                        AS rides_per_day
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE `bike_type`         = 'electric'
    AND `duration_minutes`  > 10
    AND `subscriber_type`   = 'Student Membership'
    AND LOWER(COALESCE(`start_station_name`, '')) NOT LIKE '%mobile station%'
    AND LOWER(COALESCE(`end_station_name`,   '')) NOT LIKE '%mobile station%'
    AND LOWER(COALESCE(`start_station_name`, '')) NOT LIKE '%repair shop%'
    AND LOWER(COALESCE(`end_station_name`,   '')) NOT LIKE '%repair shop%'
  GROUP BY ride_date
);