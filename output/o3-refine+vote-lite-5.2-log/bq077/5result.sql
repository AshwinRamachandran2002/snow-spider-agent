WITH monthly_counts AS (
  SELECT
    year,
    EXTRACT(MONTH FROM `date`) AS month,
    COUNT(*) AS monthly_count
  FROM
    `bigquery-public-data.chicago_crime.crime`
  WHERE
    primary_type = 'MOTOR VEHICLE THEFT'
    AND year BETWEEN 2010 AND 2016
  GROUP BY
    year, month
),
yearly_max AS (
  SELECT
    year,
    MAX(monthly_count) AS highest_monthly_thefts
  FROM
    monthly_counts
  GROUP BY
    year
)
SELECT
  year,
  highest_monthly_thefts
FROM
  yearly_max
ORDER BY
  year;