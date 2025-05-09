-- For each year (2010-2016), the greatest number of motor-vehicle thefts recorded in any single month
SELECT
  yr  AS year,
  MAX(thefts_in_month) AS highest_monthly_motor_thefts
FROM (
  SELECT
    EXTRACT(YEAR  FROM date)  AS yr,
    EXTRACT(MONTH FROM date)  AS mo,
    COUNT(*)                  AS thefts_in_month
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE primary_type = 'MOTOR VEHICLE THEFT'
    AND EXTRACT(YEAR FROM date) BETWEEN 2010 AND 2016
  GROUP BY yr, mo
) monthly_totals
GROUP BY yr
ORDER BY yr;