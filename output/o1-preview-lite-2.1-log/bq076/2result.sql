SELECT MAX(num_incidents) AS Highest_number_of_motor_vehicle_theft_incidents_in_a_month
FROM (
  SELECT EXTRACT(MONTH FROM `date`) AS month, COUNT(*) AS num_incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE `primary_type` = 'MOTOR VEHICLE THEFT' AND `year` = 2016
  GROUP BY month
) AS monthly_counts;