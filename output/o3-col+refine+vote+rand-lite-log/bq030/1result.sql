SELECT
  country_name AS country,
  CONCAT(ROUND(SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) * 100, 2), '%') AS recovery_rate_percentage
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE aggregation_level = 0
  AND date = DATE '2020-05-10'
  AND cumulative_confirmed > 50000
ORDER BY SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) DESC
LIMIT 3;