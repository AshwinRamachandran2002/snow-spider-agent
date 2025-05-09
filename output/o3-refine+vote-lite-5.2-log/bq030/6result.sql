SELECT
  country_name,
  ROUND(100 * SUM(cumulative_recovered) / SUM(cumulative_confirmed), 4) AS recovery_rate_percentage
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date = '2020-05-10'
  AND aggregation_level = 0            -- country–level records
  AND cumulative_confirmed IS NOT NULL
  AND cumulative_recovered IS NOT NULL
GROUP BY
  country_name
HAVING
  SUM(cumulative_confirmed) > 50000     -- only countries with > 50,000 confirmed cases
ORDER BY
  recovery_rate_percentage DESC
LIMIT 3;