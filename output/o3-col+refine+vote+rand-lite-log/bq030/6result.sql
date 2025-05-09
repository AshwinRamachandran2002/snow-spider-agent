SELECT
  country_name,
  ROUND(100.0 * cumulative_recovered / cumulative_confirmed, 2) AS recovery_rate_pct
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  aggregation_level = 0
  AND date = '2020-05-10'
  AND cumulative_confirmed > 50000
  AND cumulative_recovered IS NOT NULL
ORDER BY
  recovery_rate_pct DESC
LIMIT 3;