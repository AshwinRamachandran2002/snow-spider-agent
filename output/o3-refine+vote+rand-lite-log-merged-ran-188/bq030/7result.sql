WITH country_totals AS (
  SELECT
    country_name,
    MAX(cumulative_confirmed) AS confirmed,
    MAX(cumulative_recovered) AS recovered
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
        date = '2020-05-10'      -- snapshot date
    AND aggregation_level = 0    -- country–level rows
  GROUP BY country_name
)
SELECT
  country_name,
  ROUND(100 * recovered / confirmed, 4) AS recovery_rate_percent
FROM country_totals
WHERE
      confirmed > 50000          -- at least 50 000 confirmed cases
  AND recovered IS NOT NULL      -- exclude countries without recovery data
ORDER BY recovery_rate_percent DESC
LIMIT 3;