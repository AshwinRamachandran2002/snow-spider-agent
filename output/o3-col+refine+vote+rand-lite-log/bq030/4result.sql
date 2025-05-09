-- Top 3 recovery rates (as %) among countries with >50 000 confirmed cases on 2020-05-10
SELECT
  country_name,
  ROUND(SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) * 100, 2) AS recovery_rate_percent
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  aggregation_level = 0            -- country-level rows
  AND date = '2020-05-10'          -- snapshot date
  AND cumulative_confirmed > 50000 -- only countries above the threshold
ORDER BY
  recovery_rate_percent DESC
LIMIT 3;