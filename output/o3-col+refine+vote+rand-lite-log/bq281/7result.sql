SELECT MAX(daily_rides) AS max_daily_electric_student_rides_over_10min
FROM (
  SELECT
    DATE(`start_time`) AS ride_date,
    COUNT(*)           AS daily_rides
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE `subscriber_type`  = 'Student Membership'
    AND `bike_type`        = 'electric'
    AND `duration_minutes` > 10
    AND NOT (LOWER(`start_station_name`) LIKE '%mobile station%' OR
             LOWER(`start_station_name`) LIKE '%repair shop%')
    AND NOT (LOWER(`end_station_name`)   LIKE '%mobile station%' OR
             LOWER(`end_station_name`)   LIKE '%repair shop%')
  GROUP BY ride_date
);