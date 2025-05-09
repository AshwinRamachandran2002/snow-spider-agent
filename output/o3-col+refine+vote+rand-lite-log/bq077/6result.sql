-- Highest monthly counts of motor vehicle thefts for each year 2010-2016
SELECT
  yr AS year,
  MAX(monthly_thefts) AS max_motor_thefts_in_one_month
FROM (
  SELECT
    EXTRACT(YEAR  FROM `date`)  AS yr,
    EXTRACT(MONTH FROM `date`)  AS mo,
    COUNT(*)                   AS monthly_thefts
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE primary_type = 'MOTOR VEHICLE THEFT'
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2010 AND 2016
  GROUP BY yr, mo
)
GROUP BY yr
ORDER BY year;