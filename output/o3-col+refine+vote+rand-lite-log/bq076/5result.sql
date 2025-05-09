SELECT incidents AS max_monthly_motor_vehicle_thefts_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE `year` = 2016
    AND `primary_type` = 'MOTOR VEHICLE THEFT'
  GROUP BY month
  ORDER BY incidents DESC
  LIMIT 1
);