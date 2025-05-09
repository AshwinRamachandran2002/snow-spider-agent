-- Highest monthly counts of motor-vehicle thefts for each year 2010-2016
SELECT
  yr AS year,
  MAX(monthly_count) AS highest_monthly_motor_thefts
FROM (
  SELECT
    EXTRACT(YEAR  FROM `date`)  AS yr,
    EXTRACT(MONTH FROM `date`)  AS mo,
    COUNT(*)                   AS monthly_count
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE primary_type = 'MOTOR VEHICLE THEFT'
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2010 AND 2016
  GROUP BY yr, mo
)
GROUP BY yr
ORDER BY yr;