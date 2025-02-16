-- Task: For each month from 2010 to 2016, how many motor vehicle thefts occurred?
SELECT
  EXTRACT(YEAR FROM `date`) AS year,
  EXTRACT(MONTH FROM `date`) AS month,
  COUNT(*) AS theft_count
FROM
  `bigquery-public-data`.`chicago_crime`.`crime`
WHERE
  `primary_type` = 'MOTOR VEHICLE THEFT'
  AND EXTRACT(YEAR FROM `date`) BETWEEN 2010 AND 2016
GROUP BY
  year, month
ORDER BY
  year, month;