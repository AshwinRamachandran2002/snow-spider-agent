SELECT
  MAX(monthly_total) AS max_motor_vehicle_theft_incidents
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(`unique_key`)       AS monthly_total
  FROM
    `bigquery-public-data.chicago_crime.crime`
  WHERE
    `year` = 2016
    AND `primary_type` = 'MOTOR VEHICLE THEFT'
  GROUP BY
    month
);