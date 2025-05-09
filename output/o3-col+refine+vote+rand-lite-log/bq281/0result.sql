SELECT
  MAX(rides_this_day) AS highest_single_day_total
FROM (
  SELECT
    DATE(`start_time`) AS ride_date,
    COUNT(*)           AS rides_this_day
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE `subscriber_type`   = 'Student Membership'
    AND `bike_type`         = 'electric'
    AND `duration_minutes` > 10
    AND LOWER(`start_station_name`) NOT LIKE '%mobile station%'
    AND LOWER(`end_station_name`)   NOT LIKE '%mobile station%'
    AND LOWER(`start_station_name`) NOT LIKE '%repair shop%'
    AND LOWER(`end_station_name`)   NOT LIKE '%repair shop%'
  GROUP BY ride_date
);