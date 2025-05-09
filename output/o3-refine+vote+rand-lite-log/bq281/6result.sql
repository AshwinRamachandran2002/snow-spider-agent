WITH filtered_rides AS (
  SELECT
    DATE(start_time) AS ride_date
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
        subscriber_type = 'Student Membership'
    AND bike_type        = 'electric'
    AND duration_minutes > 10
    AND NOT (
            LOWER(start_station_name) LIKE '%mobile station%' OR
            LOWER(start_station_name) LIKE '%repair shop%'   OR
            LOWER(end_station_name)   LIKE '%mobile station%' OR
            LOWER(end_station_name)   LIKE '%repair shop%'
        )
),
daily_counts AS (
  SELECT
    ride_date,
    COUNT(*) AS rides_per_day
  FROM filtered_rides
  GROUP BY ride_date
)
SELECT
  MAX(rides_per_day) AS highest_single_day_ride_count
FROM daily_counts;