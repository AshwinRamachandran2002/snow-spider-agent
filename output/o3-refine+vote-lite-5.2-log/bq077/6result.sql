WITH monthly_motor_thefts AS (
  SELECT
    EXTRACT(YEAR  FROM `date`)  AS year,
    EXTRACT(MONTH FROM `date`)  AS month,
    COUNT(*)                    AS monthly_thefts
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE
    primary_type = 'MOTOR VEHICLE THEFT'
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2010 AND 2016
  GROUP BY
    year, month
)

SELECT
  year,
  MAX(monthly_thefts) AS highest_monthly_motor_thefts
FROM monthly_motor_thefts
GROUP BY year
ORDER BY year;