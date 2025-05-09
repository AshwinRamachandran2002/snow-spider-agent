WITH country_totals AS (
  -- Aggregate national-level totals for each country on 10 May 2020
  SELECT
    country_name,
    SUM(cumulative_confirmed) AS confirmed,
    SUM(cumulative_recovered) AS recovered
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-05-10'
    AND aggregation_level = 0          -- country level rows
  GROUP BY country_name
)

-- Pick the three countries (with >50 000 cases) that have the highest recovery rate
SELECT
  country_name,
  confirmed                       AS cumulative_confirmed,
  recovered                       AS cumulative_recovered,
  ROUND(100 * SAFE_DIVIDE(recovered, confirmed), 2) AS recovery_rate_pct
FROM country_totals
WHERE confirmed > 50000
ORDER BY recovery_rate_pct DESC
LIMIT 3;