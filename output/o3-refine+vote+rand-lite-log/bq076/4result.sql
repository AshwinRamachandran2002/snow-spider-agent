-- Highest number of motor vehicle theft incidents
-- that occurred in any single month during 2016
SELECT
  MAX(month_count) AS highest_monthly_incidents_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS month_count
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE
    year = 2016
    AND primary_type = 'MOTOR VEHICLE THEFT'
  GROUP BY month
);