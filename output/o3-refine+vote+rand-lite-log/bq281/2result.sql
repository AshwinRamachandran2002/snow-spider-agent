-- highest number of qualifying e‑bike rides taken in one day
WITH daily_student_ebike_rides AS (
  SELECT
    DATE(start_time) AS ride_date,
    COUNT(*) AS daily_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
    subscriber_type = 'Student Membership'          -- only student members
    AND duration_minutes > 10                       -- rides > 10 minutes
    AND LOWER(bike_type) LIKE '%electric%'          -- electric bikes (covers “electric”, “ebike”, etc.)
    -- exclude trips that start or end at Mobile Station or Repair Shop
    AND (
          start_station_name IS NULL
          OR (LOWER(start_station_name) NOT LIKE '%mobile station%' 
              AND LOWER(start_station_name) NOT LIKE '%repair shop%')
        )
    AND (
          end_station_name IS NULL
          OR (LOWER(end_station_name) NOT LIKE '%mobile station%' 
              AND LOWER(end_station_name) NOT LIKE '%repair shop%')
        )
  GROUP BY ride_date
)
SELECT
  MAX(daily_count) AS highest_daily_ride_count
FROM daily_student_ebike_rides;