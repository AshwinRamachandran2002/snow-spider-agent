SELECT MAX(incident_count) AS Highest_number_of_motor_vehicle_theft_incidents_in_a_month
FROM (
  SELECT EXTRACT(MONTH FROM `date`) AS month, COUNT(*) AS incident_count
  FROM `bigquery-public-data`.`chicago_crime`.`crime`
  WHERE LOWER(`primary_type`) LIKE '%motor vehicle theft%' AND EXTRACT(YEAR FROM `date`) = 2016
  GROUP BY month
)