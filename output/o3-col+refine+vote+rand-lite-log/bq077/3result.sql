WITH monthly_counts AS (
  SELECT
    EXTRACT(YEAR  FROM `date`)  AS year,
    EXTRACT(MONTH FROM `date`)  AS month,
    COUNT(*)                   AS thefts
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE LOWER(`primary_type`) = 'motor vehicle theft'
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2010 AND 2016
  GROUP BY year, month
)
SELECT
  year,
  MAX(thefts) AS highest_monthly_motor_thefts
FROM monthly_counts
GROUP BY year
ORDER BY year;