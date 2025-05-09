SELECT
  MAX(month_incidents) AS highest_monthly_motor_vehicle_theft_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS month_incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE
    `year` = 2016
    AND primary_type = 'MOTOR VEHICLE THEFT'
  GROUP BY
    month
);