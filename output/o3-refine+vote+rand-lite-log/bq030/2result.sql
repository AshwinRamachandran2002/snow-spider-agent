WITH country_snapshot AS (
  SELECT
    country_name,
    cumulative_confirmed,
    cumulative_recovered,
    SAFE_DIVIDE(cumulative_recovered, cumulative_confirmed) AS recovery_rate
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
        date = '2020-05-10'          -- snapshot date
    AND aggregation_level = 0        -- country‑level rows only
    AND cumulative_confirmed > 50000 -- countries with >50,000 confirmed cases
    AND cumulative_recovered IS NOT NULL
)
SELECT
  country_name,
  ROUND(recovery_rate * 100, 4) AS recovery_rate_percentage
FROM country_snapshot
ORDER BY recovery_rate DESC
LIMIT 3;