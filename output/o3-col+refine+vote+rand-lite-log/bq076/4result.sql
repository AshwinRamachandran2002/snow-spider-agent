SELECT
  MAX(monthly_incidents) AS highest_monthly_incidents_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS monthly_incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE year = 2016
    AND primary_type = 'MOTOR VEHICLE THEFT'
  GROUP BY month
);