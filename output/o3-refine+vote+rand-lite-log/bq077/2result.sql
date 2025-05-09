-- Highest monthly counts of MOTOR VEHICLE THEFT incidents for each year 2010‑2016
SELECT
  year,
  MAX(monthly_incidents) AS highest_monthly_motor_thefts
FROM (
  SELECT
    EXTRACT(YEAR  FROM `date`)  AS year,
    EXTRACT(MONTH FROM `date`)  AS month,
    COUNT(*)                   AS monthly_incidents
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE
    primary_type = 'MOTOR VEHICLE THEFT'
    AND EXTRACT(YEAR FROM `date`) BETWEEN 2010 AND 2016
  GROUP BY year, month
)
GROUP BY year
ORDER BY year;