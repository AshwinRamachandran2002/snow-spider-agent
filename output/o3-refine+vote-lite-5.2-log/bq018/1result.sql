WITH us_daily AS (
  SELECT
    date,
    new_confirmed,
    LAG(cumulative_confirmed) OVER (ORDER BY date) AS prev_cum_confirmed
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE location_key = 'US'
    AND EXTRACT(YEAR FROM date) = 2020
    AND EXTRACT(MONTH FROM date) IN (3, 4)   -- March and April
),
rates AS (
  SELECT
    date,
    SAFE_DIVIDE(new_confirmed, prev_cum_confirmed) AS growth_rate
  FROM us_daily
  WHERE prev_cum_confirmed > 0
)
SELECT
  FORMAT_DATE('%m-%d', date) AS day_with_highest_growth
FROM rates
ORDER BY growth_rate DESC
LIMIT 1;