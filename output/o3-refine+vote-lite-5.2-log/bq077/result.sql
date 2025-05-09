-- Highest number of “MOTOR VEHICLE THEFT” incidents that occurred in any
-- single month for each year from 2010 through 2016.
SELECT
  year,
  MAX(monthly_thefts) AS max_monthly_motor_thefts
FROM (
  SELECT
    year,
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS monthly_thefts
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE
    year BETWEEN 2010 AND 2016
    AND primary_type = 'MOTOR VEHICLE THEFT'
  GROUP BY
    year,
    month
)
GROUP BY
  year
ORDER BY
  year;