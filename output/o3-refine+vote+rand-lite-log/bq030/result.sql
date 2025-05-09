-- Top three countries (as of 2020‑05‑10) with the highest COVID‑19 recovery
-- rate among those having more than 50,000 confirmed cases
WITH country_snapshot AS (
  SELECT
    country_name,
    cumulative_confirmed,
    cumulative_recovered,
    SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) * 100 AS recovery_rate_pct
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
        date = '2020-05-10'
    AND aggregation_level = 0           -- keep country‑level rows only
    AND cumulative_confirmed > 50000    -- at least 50k confirmed cases
    AND cumulative_recovered IS NOT NULL
)
SELECT
  country_name,
  ROUND(recovery_rate_pct, 2) AS recovery_rate_percentage
FROM
  country_snapshot
ORDER BY
  recovery_rate_percentage DESC
LIMIT 3;