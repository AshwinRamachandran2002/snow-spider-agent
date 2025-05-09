WITH monthly_thefts AS (
  SELECT
    `year`,
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS thefts
  FROM `bigquery-public-data.chicago_crime.crime`
  WHERE `primary_type` = 'MOTOR VEHICLE THEFT'
    AND `year` BETWEEN 2010 AND 2016
  GROUP BY `year`, month
)
SELECT
  `year`,
  MAX(thefts) AS highest_motor_thefts_in_one_month
FROM monthly_thefts
GROUP BY `year`
ORDER BY `year`;