SELECT
  country_name,
  ROUND(cumulative_recovered * 100.0 / cumulative_confirmed, 4) AS recovery_rate_percentage
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date = '2020-05-10'
  AND aggregation_level = 0                 -- country–level records
  AND cumulative_confirmed > 50000          -- at least 50,000 confirmed cases
  AND cumulative_recovered IS NOT NULL
ORDER BY
  recovery_rate_percentage DESC,
  country_name
LIMIT 3;