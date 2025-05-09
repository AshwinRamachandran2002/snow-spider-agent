WITH us AS (
  SELECT
    date,
    new_confirmed,
    LAG(cumulative_confirmed) OVER (ORDER BY date) AS prev_cum
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE location_key = 'US'
)
SELECT
  FORMAT_DATE('%m-%d', date) AS highest_growth_day
FROM us
WHERE EXTRACT(MONTH FROM date) IN (3, 4)
  AND prev_cum > 0
ORDER BY SAFE_DIVIDE(new_confirmed, prev_cum) DESC
LIMIT 1;