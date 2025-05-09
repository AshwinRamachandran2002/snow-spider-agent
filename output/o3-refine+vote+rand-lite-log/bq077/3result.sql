WITH monthly_counts AS (
  SELECT
    year,
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS motor_thefts
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE year BETWEEN 2010 AND 2016
    AND primary_type = 'MOTOR VEHICLE THEFT'
  GROUP BY year, month
),
max_monthly AS (
  SELECT
    year,
    MAX(motor_thefts) AS highest_monthly_motor_thefts
  FROM monthly_counts
  GROUP BY year
)
SELECT
  year,
  highest_monthly_motor_thefts
FROM max_monthly
ORDER BY year;