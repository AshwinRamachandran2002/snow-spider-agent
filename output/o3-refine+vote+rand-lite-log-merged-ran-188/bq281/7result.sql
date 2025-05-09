-- Highest number of electric ‟Student Membership” rides >10 minutes 
-- on any single day, excluding trips that start or finish at 
-- “Mobile Station” or “Repair Shop”.
WITH daily_counts AS (
  SELECT
    DATE(start_time) AS ride_date,
    COUNT(*)         AS rides
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
        subscriber_type = 'Student Membership'
    AND bike_type       = 'electric'
    AND duration_minutes > 10
    AND LOWER(start_station_name) NOT IN ('mobile station', 'repair shop')
    AND LOWER(end_station_name)   NOT IN ('mobile station', 'repair shop')
  GROUP BY ride_date
)

SELECT MAX(rides) AS highest_daily_ride_count
FROM daily_counts;