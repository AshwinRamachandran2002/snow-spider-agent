SELECT FORMAT_DATE('%m-%d', date) AS answer_mm_dd
FROM (
  SELECT
    date,
    SAFE_DIVIDE(new_confirmed,
                LAG(cumulative_confirmed) OVER (ORDER BY date)) AS growth_rate
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE location_key = 'US'
    AND EXTRACT(MONTH FROM date) IN (3, 4)
)
WHERE growth_rate IS NOT NULL
ORDER BY growth_rate DESC
LIMIT 1;