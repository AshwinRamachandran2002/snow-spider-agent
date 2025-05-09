SELECT
  country_name,
  ROUND(100 * cumulative_recovered / cumulative_confirmed, 2) AS recovery_rate_pct
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE date = '2020-05-10'
  AND aggregation_level = 0                      -- country-level rows
  AND cumulative_confirmed > 50000               -- only countries with > 50 000 cases
  AND cumulative_recovered IS NOT NULL           -- need a value to compute the rate
ORDER BY recovery_rate_pct DESC
LIMIT 3;