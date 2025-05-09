SELECT
  MAX(monthly_incidents) AS max_motor_vehicle_theft_incidents
FROM (
  SELECT
    COUNT(*) AS monthly_incidents
  FROM
    `bigquery-public-data.chicago_crime.crime`
  WHERE
    primary_type = 'MOTOR VEHICLE THEFT'
    AND year = 2016
  GROUP BY
    FORMAT_DATE('%Y-%m', DATE(date))
);