-- Day in March/April with the highest COVID‑19 confirmed‑case growth rate in the U.S.
WITH us_daily AS (
  SELECT
    date,
    new_confirmed,
    LAG(cumulative_confirmed) OVER (ORDER BY date) AS prev_cum
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE country_code = 'US'
    AND aggregation_level = 0                         -- national level
    AND EXTRACT(MONTH FROM date) IN (3, 4)            -- March or April
),
rates AS (
  SELECT
    FORMAT_DATE('%m-%d', date) AS day,
    SAFE_DIVIDE(new_confirmed, prev_cum) AS growth_rate
  FROM us_daily
  WHERE prev_cum > 0                                  -- avoid divide‑by‑zero
)
SELECT day
FROM rates
ORDER BY growth_rate DESC
LIMIT 1;