-- Highest number of motor-vehicle thefts that occurred
-- in any single month for each year 2010-2016
SELECT
  year,
  MAX(monthly_thefts) AS highest_monthly_motor_thefts
FROM (
  SELECT
    year,
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS monthly_thefts
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE primary_type = 'MOTOR VEHICLE THEFT'
    AND year BETWEEN 2010 AND 2016
  GROUP BY year, month
)
GROUP BY year
ORDER BY year;