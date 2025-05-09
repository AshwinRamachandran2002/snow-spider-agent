WITH filtered_trips AS (
  SELECT
    DATE(start_time) AS ride_day
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
    LOWER(subscriber_type) = 'student membership'           -- only Student Membership riders
    AND duration_minutes > 10                               -- rides longer than 10 minutes
    AND LOWER(bike_type) LIKE '%electric%'                  -- electric bikes
    AND NOT (
      LOWER(start_station_name) IN ('mobile station','repair shop') OR
      LOWER(end_station_name)   IN ('mobile station','repair shop')
    )                                                       -- exclude specified stations
),
daily_counts AS (
  SELECT
    ride_day,
    COUNT(*) AS rides_per_day
  FROM
    filtered_trips
  GROUP BY
    ride_day
)
SELECT
  MAX(rides_per_day) AS highest_single_day_ride_count
FROM
  daily_counts;