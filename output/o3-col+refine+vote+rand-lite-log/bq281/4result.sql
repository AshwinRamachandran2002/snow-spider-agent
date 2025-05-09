-- Highest single-day count of qualifying electric rides
WITH qualified_rides AS (
  SELECT
    DATE(`start_time`) AS ride_date
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE `bike_type`          = 'electric'
    AND `subscriber_type`    = 'Student Membership'
    AND `duration_minutes`  > 10
    -- exclude Mobile Stations and Repair Shops
    AND LOWER(`start_station_name`) NOT LIKE '%mobile station%'
    AND LOWER(`end_station_name`)   NOT LIKE '%mobile station%'
    AND LOWER(`start_station_name`) NOT LIKE '%repair shop%'
    AND LOWER(`end_station_name`)   NOT LIKE '%repair shop%'
)
SELECT
  ride_date,
  rides AS highest_daily_rides
FROM (
  SELECT
    ride_date,
    COUNT(*) AS rides,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
  FROM qualified_rides
  GROUP BY ride_date
)
WHERE rn = 1;