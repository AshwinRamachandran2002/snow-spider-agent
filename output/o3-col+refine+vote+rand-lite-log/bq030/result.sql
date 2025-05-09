SELECT
  country_name,
  ROUND(SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) * 100, 2) AS recovery_rate_pct
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  aggregation_level = 0                -- country-level data
  AND date = '2020-05-10'              -- 10 May 2020 snapshot
  AND cumulative_confirmed > 50000     -- only countries with > 50 000 cases
  AND cumulative_recovered IS NOT NULL -- ensure a recovery figure exists
ORDER BY
  recovery_rate_pct DESC               -- highest recovery rates first
LIMIT 3;                               -- top three countries