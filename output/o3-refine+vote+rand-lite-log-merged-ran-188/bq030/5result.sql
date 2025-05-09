-- Top 3 countries with the highest COVID‑19 recovery rates (as of 2020‑05‑10)
SELECT
  country_name,
  ROUND(SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) * 100, 2) AS recovery_rate_percent
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date = '2020-05-10'          -- snapshot date
  AND aggregation_level = 0    -- country–level rows only
  AND cumulative_confirmed > 50000     -- countries with > 50,000 confirmed cases
  AND cumulative_recovered IS NOT NULL -- ensure recovery data exists
ORDER BY
  recovery_rate_percent DESC
LIMIT 3;