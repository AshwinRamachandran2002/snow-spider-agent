SELECT
  MAX(month_incidents) AS highest_monthly_incidents_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS month_incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE
    primary_type = 'MOTOR VEHICLE THEFT'
    AND EXTRACT(YEAR FROM `date`) = 2016
  GROUP BY month
);