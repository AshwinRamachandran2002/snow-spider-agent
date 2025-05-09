-- Highest number of motor-vehicle theft incidents in any single month of 2016
SELECT
  MAX(monthly_incidents) AS highest_monthly_mv_thefts_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*)                  AS monthly_incidents
  FROM
    `bigquery-public-data.chicago_crime.crime`
  WHERE
    EXTRACT(YEAR FROM `date`) = 2016
    AND UPPER(`primary_type`) = 'MOTOR VEHICLE THEFT'
  GROUP BY
    month
);