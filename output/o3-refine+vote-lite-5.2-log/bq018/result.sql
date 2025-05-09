WITH us_daily AS (
  SELECT
    date,
    new_confirmed,
    cumulative_confirmed,
    LAG(cumulative_confirmed) OVER (ORDER BY date) AS prev_cumulative
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE location_key = 'US'
    AND EXTRACT(MONTH FROM date) IN (3,4)              -- March and April
),
rates AS (
  SELECT
    date,
    SAFE_DIVIDE(new_confirmed, prev_cumulative) AS growth_rate
  FROM us_daily
  WHERE new_confirmed IS NOT NULL
    AND prev_cumulative IS NOT NULL
    AND prev_cumulative > 0
)
SELECT
  FORMAT_DATE('%m-%d', date) AS highest_growth_day
FROM rates
ORDER BY growth_rate DESC
LIMIT 1;