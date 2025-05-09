SELECT
  country_name,
  ROUND(100 * cumulative_recovered / cumulative_confirmed, 2) AS recovery_rate_percentage
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE date = '2020-05-10'
  AND aggregation_level = 0
  AND cumulative_confirmed > 50000
  AND cumulative_recovered IS NOT NULL
ORDER BY recovery_rate_percentage DESC
LIMIT 3;