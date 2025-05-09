SELECT
  country_name AS country,
  ROUND(SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) * 100, 4) AS recovery_rate_percent
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE date = '2020-05-10'
  AND aggregation_level = 0
  AND cumulative_confirmed > 50000
  AND cumulative_recovered IS NOT NULL
  AND cumulative_recovered <= cumulative_confirmed
ORDER BY recovery_rate_percent DESC, country_name
LIMIT 3;