WITH us_daily AS (
  SELECT
    date,
    cumulative_confirmed,
    LAG(cumulative_confirmed) OVER (ORDER BY date) AS prev_cumulative
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE country_code = 'US'
    AND aggregation_level = 0            -- national total
    AND cumulative_confirmed IS NOT NULL
),
growth AS (
  SELECT
    date,
    SAFE_DIVIDE(cumulative_confirmed - prev_cumulative, prev_cumulative) AS growth_rate
  FROM us_daily
  WHERE prev_cumulative IS NOT NULL
    AND EXTRACT(MONTH FROM date) IN (3, 4)   -- March and April
)
SELECT
  FORMAT_DATE('%m-%d', date) AS day
FROM growth
ORDER BY growth_rate DESC
LIMIT 1;