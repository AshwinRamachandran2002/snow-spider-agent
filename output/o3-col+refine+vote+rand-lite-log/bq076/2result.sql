SELECT
  MAX(monthly_incidents) AS highest_monthly_incidents_2016
FROM (
  SELECT
    COUNT(*) AS monthly_incidents
  FROM
    `bigquery-public-data.chicago_crime.crime`
  WHERE
    EXTRACT(YEAR FROM `date`) = 2016
    AND `primary_type` = 'MOTOR VEHICLE THEFT'
  GROUP BY
    EXTRACT(MONTH FROM `date`)
);