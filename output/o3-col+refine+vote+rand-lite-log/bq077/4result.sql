-- Highest monthly count of motor-vehicle thefts for each year 2010-2016
WITH monthly_totals AS (
  SELECT
    EXTRACT(YEAR  FROM `date`)  AS year,
    EXTRACT(MONTH FROM `date`)  AS month,
    COUNT(*)                    AS month_cnt
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE LOWER(`primary_type`) = 'motor vehicle theft'
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2010 AND 2016
  GROUP BY year, month
)
SELECT
  year,
  MAX(month_cnt) AS highest_monthly_motor_thefts
FROM monthly_totals
GROUP BY year
ORDER BY year;