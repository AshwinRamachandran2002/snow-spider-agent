WITH eligible_rides AS (
  SELECT
    DATE(start_time) AS ride_date
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
    subscriber_type = 'Student Membership'
    AND LOWER(bike_type) LIKE '%electric%'          -- electric bikes only
    AND duration_minutes > 10                       -- rides longer than 10 minutes
    -- exclude any ride that starts OR ends at Mobile Station or Repair Shop
    AND NOT REGEXP_CONTAINS(LOWER(start_station_name), r'(mobile station|repair shop)')
    AND NOT REGEXP_CONTAINS(LOWER(end_station_name)  , r'(mobile station|repair shop)')
)

SELECT
  MAX(daily_ride_count) AS highest_daily_electric_ride_total
FROM (
  SELECT
    ride_date,
    COUNT(*) AS daily_ride_count
  FROM
    eligible_rides
  GROUP BY
    ride_date
);