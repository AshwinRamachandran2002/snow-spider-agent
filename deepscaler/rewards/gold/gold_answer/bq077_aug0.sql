-- Task: For each year from 2010 to 2016, determine the highest number of motor vehicle thefts that occurred in any single month within that year.
SELECT
  year,
  MAX(theft_count) AS Highest_Number_of_Motor_Thefts_in_One_Month
FROM (
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
)
GROUP BY
  year
ORDER BY
  year;