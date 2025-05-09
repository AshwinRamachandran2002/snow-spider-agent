SELECT
  country_name,
  ROUND(SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) * 100, 4) AS recovery_rate_percentage
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date = '2020-05-10'
  AND aggregation_level = 0              -- country-level data
  AND cumulative_confirmed > 50000       -- at least 50,000 confirmed cases
  AND cumulative_recovered IS NOT NULL
ORDER BY
  recovery_rate_percentage DESC
LIMIT 3;