-- The query returns the single-day record count of qualifying electric-bike rides
SELECT MAX(daily_count) AS highest_number_of_electric_student_rides_in_a_single_day
FROM (
  SELECT
    DATE(`start_time`) AS ride_date,
    COUNT(*)           AS daily_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
    `subscriber_type`         = 'Student Membership'          -- student riders only
    AND LOWER(`bike_type`)     = 'electric'                    -- electric bikes
    AND `duration_minutes`    > 10                             -- longer than 10 minutes
    -- exclude any ride that starts or ends at Mobile Station or Repair Shop
    AND NOT REGEXP_CONTAINS(IFNULL(LOWER(`start_station_name`), ''), r'(mobile station|repair shop)')
    AND NOT REGEXP_CONTAINS(IFNULL(LOWER(`end_station_name`),   ''), r'(mobile station|repair shop)')
  GROUP BY ride_date
);