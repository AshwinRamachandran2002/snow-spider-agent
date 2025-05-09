-- Highest number of motor vehicle theft incidents in any single month of 2016
WITH monthly_thefts AS (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE
    year = 2016
    AND primary_type = 'MOTOR VEHICLE THEFT'
  GROUP BY month
)
SELECT
  MAX(incidents) AS highest_monthly_incidents_2016
FROM monthly_thefts;