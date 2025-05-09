SELECT
  MAX(monthly_count) AS max_motor_vehicle_thefts_in_a_month_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS monthly_count
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE year = 2016
    AND primary_type = 'MOTOR VEHICLE THEFT'
  GROUP BY month
);