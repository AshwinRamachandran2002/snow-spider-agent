-- Highest count of motor-vehicle-theft incidents in any single month of 2016
SELECT
  MAX(monthly_incidents) AS highest_monthly_mv_theft_2016
FROM (
  SELECT
    EXTRACT(MONTH FROM `date`) AS month_num,
    COUNT(*)                 AS monthly_incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE `year` = 2016
    AND `primary_type` = 'MOTOR VEHICLE THEFT'
  GROUP BY month_num
);