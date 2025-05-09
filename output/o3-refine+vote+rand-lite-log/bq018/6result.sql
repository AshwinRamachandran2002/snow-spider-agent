WITH us_daily AS (
  SELECT
    date,
    new_confirmed,
    cumulative_confirmed,
    LAG(cumulative_confirmed) OVER (ORDER BY date) AS prev_cumulative
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    location_key = 'US'           -- United States, national level
    AND aggregation_level = 0     -- country aggregation
    AND date BETWEEN '2020-03-01' AND '2020-04-30'  -- March & April 2020
),
growth_rates AS (
  SELECT
    date,
    SAFE_DIVIDE(new_confirmed, prev_cumulative) AS growth_rate
  FROM us_daily
  WHERE prev_cumulative > 0        -- avoid division by zero / null
)
SELECT
  FORMAT_DATE('%m-%d', date) AS highest_growth_day
FROM growth_rates
ORDER BY growth_rate DESC
LIMIT 1;