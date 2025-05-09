WITH monthly AS (
  SELECT
    year,
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS motor_thefts
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE primary_type = 'MOTOR VEHICLE THEFT'
    AND year BETWEEN 2010 AND 2016
  GROUP BY year, month
)
SELECT
  year,
  MAX(motor_thefts) AS max_monthly_motor_thefts
FROM monthly
GROUP BY year
ORDER BY year;