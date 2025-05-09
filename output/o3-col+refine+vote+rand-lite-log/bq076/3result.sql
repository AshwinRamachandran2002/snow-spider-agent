SELECT
  MAX(monthly_incident_count) AS max_monthly_motor_vehicle_theft_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month_num,
    COUNT(*)                  AS monthly_incident_count
  FROM
    `bigquery-public-data.chicago_crime.crime`
  WHERE
    `year` = 2016
    AND `primary_type` = 'MOTOR VEHICLE THEFT'
  GROUP BY
    month_num
);