WITH filtered_rides AS (
  SELECT
    DATE(start_time) AS ride_date
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
    bike_type = 'electric'                       -- only electric bikes
    AND duration_minutes > 10                    -- rides longer than 10 minutes
    AND subscriber_type = 'Student Membership'   -- subscriber type filter
    AND start_station_name NOT IN ('Mobile Station', 'Repair Shop')  -- exclude disallowed stations
    AND end_station_name   NOT IN ('Mobile Station', 'Repair Shop')
),
daily_counts AS (
  SELECT
    ride_date,
    COUNT(*) AS rides_on_day
  FROM
    filtered_rides
  GROUP BY
    ride_date
)
SELECT
  MAX(rides_on_day) AS highest_daily_ride_count
FROM
  daily_counts;