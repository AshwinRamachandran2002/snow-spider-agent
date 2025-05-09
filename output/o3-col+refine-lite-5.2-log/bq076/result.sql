SELECT
  MAX(monthly_incidents) AS highest_monthly_incidents_2016
FROM (
  SELECT
    COUNT(*) AS monthly_incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE primary_type = 'MOTOR VEHICLE THEFT'
    AND year = 2016
  GROUP BY EXTRACT(MONTH FROM date)
);